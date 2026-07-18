import 'package:core/core.dart';
import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/journal/exchange_journal.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen_model.dart';
import 'package:crypto_position/src/presentation/journal/monthly_pnl_summary.dart';
import 'package:elementary/elementary.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Journal tab: a per-exchange closed-trades journal (Bybit, OKX), each backed
/// by its own [ExchangeJournal] and reloaded when its session connects.
class JournalScreenWm extends WidgetModel<JournalScreen, JournalScreenModel> {
  final BybitSessionService _bybit;
  final OkxSessionService _okx;
  final BitgetSessionService _bitget;
  final GateSessionService _gate;
  final MexcSessionService _mexc;

  late final ExchangeJournal bybitJournal = ExchangeJournal(_fetchBybit);
  late final ExchangeJournal okxJournal = ExchangeJournal(_fetchOkx);
  late final ExchangeJournal bitgetJournal = ExchangeJournal(_fetchBitget);
  late final ExchangeJournal gateJournal = ExchangeJournal(_fetchGate);
  late final ExchangeJournal mexcJournal = ExchangeJournal(_fetchMexc);

  ValueListenable<bool> get bybitHasCredentials => _bybit.hasCredentials;
  ValueListenable<bool> get okxHasCredentials => _okx.hasCredentials;
  ValueListenable<bool> get bitgetHasCredentials => _bitget.hasCredentials;
  ValueListenable<bool> get gateHasCredentials => _gate.hasCredentials;
  ValueListenable<bool> get mexcHasCredentials => _mexc.hasCredentials;

  late final List<ExchangeJournal> _journals = [
    bybitJournal,
    okxJournal,
    bitgetJournal,
    gateJournal,
    mexcJournal,
  ];

  /// The month shared by every tab's calendar and the summary card; changing it
  /// from any calendar (via [changeMonth]) moves them all together.
  DateTime _selectedMonth = _thisMonth();

  /// Realized PnL for [_selectedMonth], summed across every connected exchange's
  /// loaded closed trades. Shown above the tab bar; recomputed whenever a
  /// journal reloads.
  final _monthlyPnl = ValueNotifier<MonthlyPnlSummary>(
    MonthlyPnlSummary(month: _thisMonth()),
  );
  ValueListenable<MonthlyPnlSummary> get monthlyPnl => _monthlyPnl;

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  JournalScreenWm(
    super.model, {
    required BybitSessionService bybit,
    required OkxSessionService okx,
    required BitgetSessionService bitget,
    required GateSessionService gate,
    required MexcSessionService mexc,
  })  : _bybit = bybit,
        _okx = okx,
        _bitget = bitget,
        _gate = gate,
        _mexc = mexc;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _bybit.session.addListener(_onBybitSessionChanged);
    _okx.session.addListener(_onOkxSessionChanged);
    _bitget.session.addListener(_onBitgetSessionChanged);
    _gate.session.addListener(_onGateSessionChanged);
    _mexc.session.addListener(_onMexcSessionChanged);
    for (final journal in _journals) {
      journal.trades.addListener(_recomputePnl);
      journal.loading.addListener(_recomputePnl);
    }
    if (_bybit.session.value != null) bybitJournal.load();
    if (_okx.session.value != null) okxJournal.load();
    if (_bitget.session.value != null) bitgetJournal.load();
    if (_gate.session.value != null) gateJournal.load();
    if (_mexc.session.value != null) mexcJournal.load();
    _recomputePnl();
  }

  @override
  void dispose() {
    _bybit.session.removeListener(_onBybitSessionChanged);
    _okx.session.removeListener(_onOkxSessionChanged);
    _bitget.session.removeListener(_onBitgetSessionChanged);
    _gate.session.removeListener(_onGateSessionChanged);
    _mexc.session.removeListener(_onMexcSessionChanged);
    for (final journal in _journals) {
      journal.trades.removeListener(_recomputePnl);
      journal.loading.removeListener(_recomputePnl);
    }
    _monthlyPnl.dispose();
    bybitJournal.dispose();
    okxJournal.dispose();
    bitgetJournal.dispose();
    gateJournal.dispose();
    mexcJournal.dispose();
    super.dispose();
  }

  int get _connectedCount => [
        _bybit.session.value,
        _okx.session.value,
        _bitget.session.value,
        _gate.session.value,
        _mexc.session.value,
      ].where((session) => session != null).length;

  /// Moves every tab's calendar and the summary card to [month] and reloads,
  /// so the whole screen stays on one month. Called from any tab's calendar.
  void changeMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    for (final journal in _journals) {
      journal.changeMonth(_selectedMonth);
    }
    _recomputePnl();
  }

  /// Sums the realized PnL of the closed trades already loaded by each journal
  /// for [_selectedMonth]. A dash (null) shows only when nothing is connected.
  void _recomputePnl() {
    if (_connectedCount == 0) {
      _monthlyPnl.value = MonthlyPnlSummary(month: _selectedMonth);
      return;
    }
    final loading = _journals.any((journal) => journal.loading.value);
    final total = _journals.fold<double>(
      0,
      (sum, journal) =>
          sum +
          journal.trades.value.fold<double>(
            0,
            (tradeSum, trade) => tradeSum + trade.closedPnl,
          ),
    );
    _monthlyPnl.value = MonthlyPnlSummary(
      month: _selectedMonth,
      pnl: total,
      loading: loading,
    );
  }

  void _onBybitSessionChanged() {
    _bybit.session.value != null ? bybitJournal.load() : bybitJournal.clear();
  }

  void _onOkxSessionChanged() {
    _okx.session.value != null ? okxJournal.load() : okxJournal.clear();
  }

  void _onBitgetSessionChanged() {
    _bitget.session.value != null
        ? bitgetJournal.load()
        : bitgetJournal.clear();
  }

  void _onGateSessionChanged() {
    _gate.session.value != null ? gateJournal.load() : gateJournal.clear();
  }

  void _onMexcSessionChanged() {
    _mexc.session.value != null ? mexcJournal.load() : mexcJournal.clear();
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchBybit(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _bybit.session.value;
    if (session == null) return const Ok([]);

    final all = <ClosedTradeModel>[];
    for (final category in ['linear', 'inverse']) {
      final result = await session.repository.fetchClosedTrades(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      switch (result) {
        case Ok(:final value):
          all.addAll(value);
        case Err(:final error):
          return Err(error);
      }
    }
    return Ok(all);
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchOkx(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _okx.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchBitget(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _bitget.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchGate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _gate.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchMexc(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _mexc.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

JournalScreenWm journalScreenWmFactory({required BuildContext context}) {
  return JournalScreenWm(
    JournalScreenModel(),
    bybit: context.read<BybitSessionService>(),
    okx: context.read<OkxSessionService>(),
    bitget: context.read<BitgetSessionService>(),
    gate: context.read<GateSessionService>(),
    mexc: context.read<MexcSessionService>(),
  );
}
