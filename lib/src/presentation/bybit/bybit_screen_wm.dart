import 'dart:async';

import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class BybitScreenWm extends WidgetModel<BybitScreen, BybitScreenModel> {
  final apiKeyController = TextEditingController();
  final apiSecretController = TextEditingController();

  final ValueNotifier<bool> _hasCredentials = ValueNotifier(false);
  final ValueNotifier<WalletBalance?> _balance = ValueNotifier(null);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  final ValueNotifier<List<ClosedTrade>> _trades = ValueNotifier([]);
  final ValueNotifier<bool> _tradesLoading = ValueNotifier(false);
  final ValueNotifier<DateTime> _selectedMonth = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final ValueNotifier<DateTime?> _selectedDay = ValueNotifier(null);

  ValueListenable<bool> get hasCredentials => _hasCredentials;
  ValueListenable<WalletBalance?> get balance => _balance;
  ValueListenable<bool> get loading => _loading;
  ValueListenable<String?> get error => _error;
  ValueListenable<List<ClosedTrade>> get trades => _trades;
  ValueListenable<bool> get tradesLoading => _tradesLoading;
  ValueListenable<DateTime> get selectedMonth => _selectedMonth;
  ValueListenable<DateTime?> get selectedDay => _selectedDay;

  final BybitConfig _config;
  final DioClientFactory _dioFactory;
  final WsClientFactory _wsFactory;

  BybitRepository? _repository;
  StreamSubscription? _wsSub;

  BybitScreenWm(
    super.model, {
    required BybitConfig config,
    required DioClientFactory dioFactory,
    required WsClientFactory wsFactory,
  }) : _config = config,
       _dioFactory = dioFactory,
       _wsFactory = wsFactory;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _checkCredentials();
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    apiSecretController.dispose();
    _wsSub?.cancel();
    _repository?.dispose();
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
    _wsSub?.cancel();
    _repository?.dispose();
    _repository = null;
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

  List<ClosedTrade> tradesForDay(DateTime day) {
    return _trades.value.where((t) {
      return t.createdAt.year == day.year &&
          t.createdAt.month == day.month &&
          t.createdAt.day == day.day;
    }).toList();
  }

  Future<void> _connectApi(String apiKey, String apiSecret) async {
    _loading.value = true;
    _error.value = null;

    final dio = _dioFactory.create(
      config: _config,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    final wsChannel = _wsFactory.create(
      config: _config,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );

    final restClient = BybitRestClient(dio);
    final wsClient = BybitWsClient(wsChannel);

    _repository = BybitRepository(restClient: restClient, wsClient: wsClient);

    try {
      final walletBalance = await _repository!.fetchBalance();
      _balance.value = walletBalance;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }

    _wsSub = _repository!.walletUpdates.listen((update) {
      _balance.value = update;
    });
    _repository!.connectWs();

    await _loadTrades();
  }

  Future<void> _loadTrades() async {
    if (_repository == null) return;
    _tradesLoading.value = true;

    final month = _selectedMonth.value;
    final startDate = DateTime(month.year, month.month);
    final endDate = DateTime(month.year, month.month + 1);

    try {
      final result = await _repository!.fetchClosedTrades(
        startDate: startDate,
        endDate: endDate,
      );
      _trades.value = result;
    } catch (_) {
      _trades.value = [];
    } finally {
      _tradesLoading.value = false;
    }
  }
}

BybitScreenWm bybitScreenWmFactory({required BuildContext context}) {
  return BybitScreenWm(
    BybitScreenModel(context.read<FlutterSecureStorage>()),
    config: context.read<BybitConfig>(),
    dioFactory: context.read<DioClientFactory>(),
    wsFactory: context.read<WsClientFactory>(),
  );
}
