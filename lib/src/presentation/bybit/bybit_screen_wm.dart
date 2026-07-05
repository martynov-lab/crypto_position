import 'package:bybit/bybit.dart';
import 'package:core/core.dart';
import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BybitScreenWm extends WidgetModel<BybitScreen, BybitScreenModel> {
  final apiKeyController = TextEditingController();
  final apiSecretController = TextEditingController();

  final ValueNotifier<List<ClosedTradeModel>> _trades = ValueNotifier([]);
  final ValueNotifier<bool> _tradesLoading = ValueNotifier(false);
  final ValueNotifier<DateTime> _selectedMonth = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final ValueNotifier<DateTime?> _selectedDay = ValueNotifier(null);
  final ValueNotifier<String?> _tradesError = ValueNotifier(null);

  ValueListenable<bool> get hasCredentials => _sessionService.hasCredentials;
  ValueListenable<BybitAccountSession?> get session => _sessionService.session;
  ValueListenable<bool> get loading => _sessionService.loading;
  ValueListenable<String?> get error => _error;
  ValueListenable<List<ClosedTradeModel>> get trades => _trades;
  ValueListenable<bool> get tradesLoading => _tradesLoading;
  ValueListenable<DateTime> get selectedMonth => _selectedMonth;
  ValueListenable<DateTime?> get selectedDay => _selectedDay;

  final BybitSessionService _sessionService;

  /// Connection errors from the session merged with trades errors.
  final ValueNotifier<String?> _error = ValueNotifier(null);

  BybitScreenWm(super.model, {required BybitSessionService sessionService})
    : _sessionService = sessionService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _sessionService.error.addListener(_syncError);
    _tradesError.addListener(_syncError);
    _syncError();
    _sessionService.session.addListener(_onSessionChanged);
    if (_sessionService.session.value != null) {
      _loadTrades();
    }
  }

  @override
  void dispose() {
    _sessionService.error.removeListener(_syncError);
    _sessionService.session.removeListener(_onSessionChanged);
    apiKeyController.dispose();
    apiSecretController.dispose();
    super.dispose();
  }

  Future<void> saveCredentials() async {
    final key = apiKeyController.text.trim();
    final secret = apiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await _sessionService.saveCredentials(key, secret);
  }

  Future<void> logout() async {
    _trades.value = [];
    _tradesError.value = null;
    await _sessionService.logout();
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

  void _syncError() {
    _error.value = _sessionService.error.value ?? _tradesError.value;
  }

  void _onSessionChanged() {
    if (_sessionService.session.value != null) {
      _loadTrades();
    } else {
      _trades.value = [];
    }
  }

  Future<void> _loadTrades() async {
    final session = _sessionService.session.value;
    if (session == null) return;
    _tradesLoading.value = true;
    _tradesError.value = null;

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
      if (_sessionService.session.value != session) return;
      switch (result) {
        case Ok(:final value):
          allTrades.addAll(value);
        case Err(:final error):
          _tradesError.value = 'Ошибка загрузки сделок: $error';
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
    BybitScreenModel(),
    sessionService: context.read<BybitSessionService>(),
  );
}
