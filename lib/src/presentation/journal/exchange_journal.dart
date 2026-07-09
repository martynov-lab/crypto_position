import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

typedef ClosedTradesFetch = Future<Result<List<ClosedTradeModel>, Object>>
    Function(DateTime startDate, DateTime endDate);

/// Drives one exchange's trade journal: the selected month/day, the loaded
/// closed trades and their per-day aggregation. Two of these back the Journal
/// tab (Bybit, OKX), each fetching from its own exchange.
class ExchangeJournal {
  final ClosedTradesFetch _fetch;

  final ValueNotifier<List<ClosedTradeModel>> trades = ValueNotifier([]);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<DateTime> selectedMonth = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final ValueNotifier<DateTime?> selectedDay = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  ExchangeJournal(this._fetch);

  Map<DateTime, double> get dailyPnl {
    final map = <DateTime, double>{};
    for (final trade in trades.value) {
      final day = _dayOf(trade.createdAt);
      map[day] = (map[day] ?? 0) + trade.closedPnl;
    }
    return map;
  }

  Map<DateTime, int> get dailyTradeCount {
    final map = <DateTime, int>{};
    for (final trade in trades.value) {
      final day = _dayOf(trade.createdAt);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  List<ClosedTradeModel> tradesForDay(DateTime day) {
    return trades.value.where((t) {
      return t.createdAt.year == day.year &&
          t.createdAt.month == day.month &&
          t.createdAt.day == day.day;
    }).toList();
  }

  void selectDay(DateTime? day) {
    selectedDay.value = day;
  }

  void changeMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
    selectedDay.value = null;
    load();
  }

  Future<void> load() async {
    final month = selectedMonth.value;
    loading.value = true;
    error.value = null;

    final result = await _fetch(
      DateTime(month.year, month.month),
      DateTime(month.year, month.month + 1),
    );
    // A newer changeMonth superseded this request; let the latest one win.
    if (selectedMonth.value != month) return;

    switch (result) {
      case Ok(:final value):
        trades.value = [...value]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case Err(:final error):
        this.error.value = 'Ошибка загрузки сделок: $error';
        trades.value = [];
    }
    loading.value = false;
  }

  void clear() {
    trades.value = [];
    error.value = null;
    loading.value = false;
  }

  void dispose() {
    trades.dispose();
    loading.dispose();
    selectedMonth.dispose();
    selectedDay.dispose();
    error.dispose();
  }

  static DateTime _dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
