import 'dart:async';

import 'package:bybit/bybit.dart';
import 'package:core/core.dart';
import 'package:crypto_position/src/bybit_account_repository_factory.dart';
import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network/network.dart';
import 'package:provider/provider.dart';

class BybitScreenWm extends WidgetModel<BybitScreen, BybitScreenModel> {
  final apiKeyController = TextEditingController();
  final apiSecretController = TextEditingController();

  final ValueNotifier<bool> _hasCredentials = ValueNotifier(false);
  final ValueNotifier<WalletBalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  final ValueNotifier<List<ClosedTradeModel>> _trades = ValueNotifier([]);
  final ValueNotifier<bool> _tradesLoading = ValueNotifier(false);
  final ValueNotifier<DateTime> _selectedMonth = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final ValueNotifier<DateTime?> _selectedDay = ValueNotifier(null);

  ValueListenable<bool> get hasCredentials => _hasCredentials;
  ValueListenable<WalletBalanceModel?> get balance => _balance;
  ValueListenable<bool> get loading => _loading;
  ValueListenable<String?> get error => _error;
  ValueListenable<List<ClosedTradeModel>> get trades => _trades;
  ValueListenable<bool> get tradesLoading => _tradesLoading;
  ValueListenable<DateTime> get selectedMonth => _selectedMonth;
  ValueListenable<DateTime?> get selectedDay => _selectedDay;

  final BybitAccountRepositoryFactory _accountFactory;
  final ReconnectionService _reconnectionService;

  BybitAccountSession? _session;
  StreamSubscription<WalletBalanceModel>? _wsSub;

  BybitScreenWm(
    super.model, {
    required BybitAccountRepositoryFactory accountFactory,
    required ReconnectionService reconnectionService,
  }) : _accountFactory = accountFactory,
       _reconnectionService = reconnectionService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _checkCredentials();
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    apiSecretController.dispose();
    _closeSession();
    super.dispose();
  }

  Future<void> _checkCredentials() async {
    final apiKey = await model.getApiKey();
    final apiSecret = await model.getApiSecret();
    if (apiKey != null && apiSecret != null && apiKey.isNotEmpty) {
      _hasCredentials.value = true;
      _connectApi(apiKey, apiSecret);
    }
  }

  Future<void> saveCredentials() async {
    final key = apiKeyController.text.trim();
    final secret = apiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await model.saveCredentials(key, secret);
    _hasCredentials.value = true;
    _connectApi(key, secret);
  }

  Future<void> logout() async {
    _closeSession();
    _balance.value = null;
    _trades.value = [];
    await model.clearCredentials();
    _hasCredentials.value = false;
  }

  void selectDay(DateTime? day) {
    _selectedDay.value = day;
  }

  void changeMonth(DateTime month) {
    _selectedMonth.value = DateTime(month.year, month.month);
    _selectedDay.value = null;
    _loadTrades();
  }

  Map<DateTime, double> get dailyPnl {
    final map = <DateTime, double>{};
    for (final trade in _trades.value) {
      final day = DateTime(
        trade.createdAt.year,
        trade.createdAt.month,
        trade.createdAt.day,
      );
      map[day] = (map[day] ?? 0) + trade.closedPnl;
    }
    return map;
  }

  Map<DateTime, int> get dailyTradeCount {
    final map = <DateTime, int>{};
    for (final trade in _trades.value) {
      final day = DateTime(
        trade.createdAt.year,
        trade.createdAt.month,
        trade.createdAt.day,
      );
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  List<ClosedTradeModel> tradesForDay(DateTime day) {
    return _trades.value.where((t) {
      return t.createdAt.year == day.year &&
          t.createdAt.month == day.month &&
          t.createdAt.day == day.day;
    }).toList();
  }

  Future<void> _wsConnect() async => _session?.wsManager.start();

  Future<void> _wsDisconnect() async => _session?.wsManager.stop();

  void _closeSession() {
    _reconnectionService
      ..removeOnConnectedAction(_wsConnect)
      ..removeOnDisconnectedAction(_wsDisconnect);
    _wsSub?.cancel();
    _wsSub = null;
    _session?.dispose();
    _session = null;
  }

  Future<void> _connectApi(String apiKey, String apiSecret) async {
    _loading.value = true;
    _error.value = null;

    final session = _accountFactory.create(
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    _session = session;

    final result = await session.repository.fetchWalletBalance();
    if (_session != session) return;
    result.fold(
      (balance) => _balance.value = balance,
      (error) => _error.value = error.toString(),
    );
    _loading.value = false;

    _wsSub = session.repository.walletUpdates.listen((update) {
      _balance.value = update;
    });
    unawaited(session.wsManager.start());
    _reconnectionService
      ..addOnConnectedAction(_wsConnect)
      ..addOnDisconnectedAction(_wsDisconnect);

    await _loadTrades();
  }

  Future<void> _loadTrades() async {
    final session = _session;
    if (session == null) return;
    _tradesLoading.value = true;
    _error.value = null;

    final month = _selectedMonth.value;
    final startDate = DateTime(month.year, month.month);
    final endDate = DateTime(month.year, month.month + 1);

    final allTrades = <ClosedTradeModel>[];
    for (final category in ['linear', 'inverse']) {
      final result = await session.repository.fetchClosedTrades(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      if (_session != session) return;
      switch (result) {
        case Ok(:final value):
          allTrades.addAll(value);
        case Err(:final error):
          _error.value = 'Ошибка загрузки сделок: $error';
          _trades.value = [];
          _tradesLoading.value = false;
          return;
      }
    }
    allTrades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _trades.value = allTrades;
    _tradesLoading.value = false;
  }
}

BybitScreenWm bybitScreenWmFactory({required BuildContext context}) {
  return BybitScreenWm(
    BybitScreenModel(context.read<FlutterSecureStorage>()),
    accountFactory: context.read<BybitAccountRepositoryFactory>(),
    reconnectionService: context.read<ReconnectionService>(),
  );
}
