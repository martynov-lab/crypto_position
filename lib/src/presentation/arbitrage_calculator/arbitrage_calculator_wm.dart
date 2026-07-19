import 'dart:async';
import 'dart:math' as math;

import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/market_data_registry.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_model.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_math.dart';
import 'package:crypto_position/src/trade/arbitrage_entry_controller.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:elementary/elementary.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One point on the live spread chart.
class SpreadSample {
  final int tsMs;
  final double spreadPct;
  const SpreadSample(this.tsMs, this.spreadPct);
}

/// Available leverage steps for the slider.
const kLeverageSteps = <double>[1, 3, 5, 10, 15, 20, 25];

/// Selectable chart timeframes, in minutes (bucket size per plotted point).
/// `0` means raw ticks (one point per 2s sample, no bucketing).
const kTimeframesMin = <int>[0, 1, 5, 15];

/// Live-data poll cadence and how many raw samples are retained.
const _pollInterval = Duration(seconds: 2);

/// Cap on retained raw (2s) samples (~3h). Bounds memory; the display buckets
/// these by the selected timeframe, so history survives timeframe switches.
const _maxSamples = 5400;

class ArbitrageCalculatorWm
    extends WidgetModel<ArbitrageCalculator, ArbitrageCalculatorModel>
    with WidgetsBindingObserver {
  final MarketDataRegistry _registry;
  final FeeSettingsStore _feeStore;
  final ArbitrageEntryController _entryController;

  ArbitrageCalculatorWm(
    super.model, {
    required MarketDataRegistry registry,
    required FeeSettingsStore feeStore,
    required ArbitrageEntryController entryController,
  }) : _registry = registry,
       _feeStore = feeStore,
       _entryController = entryController;

  // Inputs.
  final searchController = TextEditingController();
  final capital1Controller = TextEditingController(text: '100');
  final capital2Controller = TextEditingController(text: '100');
  final holdingHoursController = TextEditingController(text: '1');
  final entrySpreadController = TextEditingController();
  final exitSpreadController = TextEditingController();

  final _leverage = ValueNotifier<double>(5);
  final _timeframeMin = ValueNotifier<int>(kTimeframesMin.first);

  // Catalog: per-exchange base -> instrument, and base -> covering exchanges.
  final _byExchange = <ExchangeId, Map<String, PerpInstrument>>{};
  final _basesToExchanges = <String, Set<ExchangeId>>{};

  // Selection.
  final _selectedBase = ValueNotifier<String?>(null);
  final _exchange1 = ValueNotifier<ExchangeId?>(null);
  final _exchange2 = ValueNotifier<ExchangeId?>(null);
  final _candidates = ValueNotifier<List<String>>(const []);

  // Live data.
  final _quote1 = ValueNotifier<Quote?>(null);
  final _quote2 = ValueNotifier<Quote?>(null);
  final _funding1 = ValueNotifier<FundingInfo?>(null);
  final _funding2 = ValueNotifier<FundingInfo?>(null);
  final _spreadSeries = ValueNotifier<List<SpreadSample>>(const []);
  final _dataError = ValueNotifier<String?>(null);
  final _catalogLoading = ValueNotifier<bool>(false);

  // Latest depth snapshots, kept for the fill simulation in [calculate].
  OrderBook? _book1;
  OrderBook? _book2;

  // Result.
  final _result = ValueNotifier<ArbitrageResult?>(null);

  // Fill estimates per leg, from the latest depth snapshot (see [calculate]).
  final _fill1 = ValueNotifier<FillEstimate?>(null);
  final _fill2 = ValueNotifier<FillEstimate?>(null);

  // Entry (trading) state.
  final _entryPlan = ValueNotifier<EntryPlan?>(null);
  final _canaryReport = ValueNotifier<CanaryReport?>(null);
  final _entryReport = ValueNotifier<EntryReport?>(null);
  final _entryBusy = ValueNotifier<bool>(false);

  Timer? _pollTimer;
  int _pollGen = 0;

  // Exposed listenables.
  ValueListenable<double> get leverage => _leverage;
  ValueListenable<int> get timeframeMin => _timeframeMin;
  ValueListenable<String?> get selectedBase => _selectedBase;
  ValueListenable<ExchangeId?> get exchange1 => _exchange1;
  ValueListenable<ExchangeId?> get exchange2 => _exchange2;
  ValueListenable<List<String>> get candidates => _candidates;
  ValueListenable<Quote?> get quote1 => _quote1;
  ValueListenable<Quote?> get quote2 => _quote2;
  ValueListenable<FundingInfo?> get funding1 => _funding1;
  ValueListenable<FundingInfo?> get funding2 => _funding2;
  ValueListenable<List<SpreadSample>> get spreadSeries => _spreadSeries;
  ValueListenable<String?> get dataError => _dataError;
  ValueListenable<bool> get catalogLoading => _catalogLoading;
  ValueListenable<ArbitrageResult?> get result => _result;
  ValueListenable<FillEstimate?> get fill1 => _fill1;
  ValueListenable<FillEstimate?> get fill2 => _fill2;
  ValueListenable<EntryPlan?> get entryPlan => _entryPlan;
  ValueListenable<CanaryReport?> get canaryReport => _canaryReport;
  ValueListenable<EntryReport?> get entryReport => _entryReport;
  ValueListenable<bool> get entryBusy => _entryBusy;
  Listenable get connectedListenable => _registry.connectedListenable;

  /// Current spread (leg2 vs leg1), or null before the first sample.
  double? get currentSpreadPct =>
      _spreadSeries.value.isEmpty ? null : _spreadSeries.value.last.spreadPct;

  /// All connected exchanges (regardless of the selected coin).
  List<ExchangeId> get availableExchangesAll => _registry.connected;

  /// Exchanges offering [selectedBase] that are also connected.
  List<ExchangeId> get availableExchanges {
    final base = _selectedBase.value;
    if (base == null) return const [];
    final covering = _basesToExchanges[base] ?? const {};
    return _registry.connected.where(covering.contains).toList();
  }

  double makerPct(ExchangeId e) => _feeStore.makerPct(e);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(_recomputeCandidates);
    _registry.connectedListenable.addListener(_loadCatalog);
    _loadCatalog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Returning to the foreground: timers don't fire while suspended, so
        // restart polling (without wiping the accumulated chart history) to
        // recover the data connection.
        if (_hasValidSelection &&
            (_pollTimer == null || !_pollTimer!.isActive)) {
          _startTimer();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pollTimer?.cancel();
        _pollTimer = null;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _registry.connectedListenable.removeListener(_loadCatalog);
    searchController.removeListener(_recomputeCandidates);
    searchController.dispose();
    capital1Controller.dispose();
    capital2Controller.dispose();
    holdingHoursController.dispose();
    entrySpreadController.dispose();
    exitSpreadController.dispose();
    _leverage.dispose();
    _timeframeMin.dispose();
    _selectedBase.dispose();
    _exchange1.dispose();
    _exchange2.dispose();
    _candidates.dispose();
    _quote1.dispose();
    _quote2.dispose();
    _funding1.dispose();
    _funding2.dispose();
    _spreadSeries.dispose();
    _dataError.dispose();
    _catalogLoading.dispose();
    _result.dispose();
    _fill1.dispose();
    _fill2.dispose();
    _entryPlan.dispose();
    _canaryReport.dispose();
    _entryReport.dispose();
    _entryBusy.dispose();
    super.dispose();
  }

  void setLeverage(double value) => _leverage.value = value;

  /// Switch the chart timeframe. History is kept — the display just re-buckets.
  void setTimeframe(int minutes) => _timeframeMin.value = minutes;

  void selectBase(String base) {
    _selectedBase.value = base;
    searchController.text = base;
    _candidates.value = const [];
    // Auto-pick the first two available venues.
    final available = availableExchanges;
    _exchange1.value = available.isNotEmpty ? available[0] : null;
    _exchange2.value = available.length > 1 ? available[1] : null;
    _restartPolling();
  }

  void selectExchange1(ExchangeId? e) {
    _exchange1.value = e;
    if (_exchange2.value == e) _exchange2.value = null;
    _restartPolling();
  }

  void selectExchange2(ExchangeId? e) {
    _exchange2.value = e;
    if (_exchange1.value == e) _exchange1.value = null;
    _restartPolling();
  }

  Future<void> _loadCatalog() async {
    _catalogLoading.value = true;
    _byExchange.clear();
    _basesToExchanges.clear();
    for (final exchange in _registry.connected) {
      final provider = _registry.provider(exchange);
      if (provider == null) continue;
      try {
        final instruments = await provider.fetchPerpInstruments();
        final byBase = <String, PerpInstrument>{};
        for (final ins in instruments) {
          byBase[ins.base] = ins;
          _basesToExchanges.putIfAbsent(ins.base, () => {}).add(exchange);
        }
        _byExchange[exchange] = byBase;
      } on Object catch (e) {
        _dataError.value = '${exchange.label}: $e';
      }
    }
    _catalogLoading.value = false;
    _recomputeCandidates();
  }

  void _recomputeCandidates() {
    final query = searchController.text.trim().toUpperCase();
    // Hide the list once a base is locked in (text equals the selection).
    if (query.isEmpty || query == _selectedBase.value) {
      _candidates.value = const [];
      return;
    }
    final matches = _basesToExchanges.keys
        .where((b) => b.contains(query))
        .toList()
      ..sort((a, b) {
        // Prefix matches first, then alphabetical.
        final ap = a.startsWith(query) ? 0 : 1;
        final bp = b.startsWith(query) ? 0 : 1;
        return ap != bp ? ap - bp : a.compareTo(b);
      });
    _candidates.value = matches.take(30).toList();
  }

  bool get _hasValidSelection {
    final base = _selectedBase.value;
    final e1 = _exchange1.value;
    final e2 = _exchange2.value;
    return base != null && e1 != null && e2 != null && e1 != e2;
  }

  /// Selection changed: wipe the live data and start a fresh trace.
  void _restartPolling() {
    _pollTimer?.cancel();
    _quote1.value = null;
    _quote2.value = null;
    _funding1.value = null;
    _funding2.value = null;
    _spreadSeries.value = const [];
    _result.value = null;
    _fill1.value = null;
    _fill2.value = null;
    _book1 = null;
    _book2 = null;
    _entryPlan.value = null;
    _canaryReport.value = null;
    _entryReport.value = null;
    _dataError.value = null;

    if (!_hasValidSelection) return;
    _startTimer();
  }

  /// Kick off an immediate poll and the periodic timer, keeping any existing
  /// chart history intact (used on start and on foreground resume).
  void _startTimer() {
    _pollTimer?.cancel();
    final gen = ++_pollGen;
    unawaited(_poll(gen));
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll(gen));
  }

  Future<void> _poll(int gen) async {
    final base = _selectedBase.value;
    final e1 = _exchange1.value;
    final e2 = _exchange2.value;
    if (base == null || e1 == null || e2 == null) return;
    final sym1 = _byExchange[e1]?[base]?.symbol;
    final sym2 = _byExchange[e2]?[base]?.symbol;
    final p1 = _registry.provider(e1);
    final p2 = _registry.provider(e2);
    if (sym1 == null || sym2 == null || p1 == null || p2 == null) return;

    try {
      final results = await Future.wait([
        p1.fetchQuote(sym1),
        p2.fetchQuote(sym2),
        p1.fetchFunding(sym1),
        p2.fetchFunding(sym2),
        p1.fetchOrderBook(sym1),
        p2.fetchOrderBook(sym2),
      ]);
      if (gen != _pollGen) return; // selection changed mid-flight
      final q1 = results[0] as Quote;
      final q2 = results[1] as Quote;
      _quote1.value = q1;
      _quote2.value = q2;
      _funding1.value = results[2] as FundingInfo;
      _funding2.value = results[3] as FundingInfo;
      _book1 = results[4] as OrderBook;
      _book2 = results[5] as OrderBook;
      _dataError.value = null;

      if (q1.mid > 0) {
        final spreadPct = (q2.mid - q1.mid) / q1.mid * 100;
        final now = DateTime.now().millisecondsSinceEpoch;
        final list = [
          ..._spreadSeries.value,
          SpreadSample(now, spreadPct),
        ];
        if (list.length > _maxSamples) {
          list.removeRange(0, list.length - _maxSamples);
        }
        _spreadSeries.value = list;
      }
    } on Object catch (e) {
      if (gen != _pollGen) return;
      _dataError.value = e.toString();
    }
  }

  void calculate() {
    final e1 = _exchange1.value;
    final e2 = _exchange2.value;
    final q1 = _quote1.value;
    final q2 = _quote2.value;
    final f1 = _funding1.value;
    final f2 = _funding2.value;
    if (e1 == null || e2 == null || q1 == null || q2 == null ||
        f1 == null || f2 == null) {
      return;
    }

    final input = ArbitrageInput(
      capital1: double.tryParse(capital1Controller.text) ?? 0,
      capital2: double.tryParse(capital2Controller.text) ?? 0,
      leverage: _leverage.value,
      holdingHours: double.tryParse(holdingHoursController.text) ?? 0,
      entrySpreadPct: double.tryParse(entrySpreadController.text) ?? 0,
      exitSpreadPct: double.tryParse(exitSpreadController.text) ?? 0,
      maker1Pct: _feeStore.makerPct(e1),
      maker2Pct: _feeStore.makerPct(e2),
      fundingRate1: f1.rate,
      fundingRate2: f2.rate,
      intervalHours1: f1.intervalHours,
      intervalHours2: f2.intervalHours,
      // Long the cheaper leg.
      leg1IsLong: q1.mid <= q2.mid,
    );
    _result.value = computeArbitrage(input);
    _updateFills(input.leg1IsLong);
    _buildEntryPlan(input.leg1IsLong);
  }

  /// Builds the two-leg entry plan (sizes, limit prices, per-leg validity) from
  /// the current selection, quotes and instrument filters. Cleared when the
  /// selection is incomplete or an instrument is missing.
  void _buildEntryPlan(bool leg1IsLong) {
    // A new calculation invalidates any prior canary / entry outcome.
    _canaryReport.value = null;
    _entryReport.value = null;

    final base = _selectedBase.value;
    final e1 = _exchange1.value;
    final e2 = _exchange2.value;
    final q1 = _quote1.value;
    final q2 = _quote2.value;
    if (base == null || e1 == null || e2 == null || q1 == null || q2 == null) {
      _entryPlan.value = null;
      return;
    }

    final longEx = leg1IsLong ? e1 : e2;
    final shortEx = leg1IsLong ? e2 : e1;
    final longMid = (leg1IsLong ? q1 : q2).mid;
    final longCap =
        double.tryParse((leg1IsLong ? capital1Controller : capital2Controller)
            .text) ?? 0;
    final shortCap =
        double.tryParse((leg1IsLong ? capital2Controller : capital1Controller)
            .text) ?? 0;
    final longInstr = _byExchange[longEx]?[base];
    final shortInstr = _byExchange[shortEx]?[base];
    final shortMid = (leg1IsLong ? q2 : q1).mid;
    if (longInstr == null || shortInstr == null ||
        longMid <= 0 || shortMid <= 0) {
      _entryPlan.value = null;
      return;
    }

    final lev = _leverage.value;
    final entrySpread = double.tryParse(entrySpreadController.text) ?? 0;
    final prices = entryLimitPrices(
      longMid: longMid,
      entrySpreadPct: entrySpread,
      longTick: longInstr.tickSize,
      shortTick: shortInstr.tickSize,
    );

    // Delta-neutral: match the base quantity across both legs, then convert to
    // each exchange's native order unit and round to its step.
    final baseLong = longCap * lev / prices.longPrice;
    final baseShort = shortCap * lev / prices.shortPrice;
    final matchedBase = math.min(baseLong, baseShort);
    final longQty = roundQty(
      matchedBase / (longInstr.contractSize ?? 1),
      step: longInstr.qtyStep,
      minQty: longInstr.minQty,
    );
    final shortQty = roundQty(
      matchedBase / (shortInstr.contractSize ?? 1),
      step: shortInstr.qtyStep,
      minQty: shortInstr.minQty,
    );

    _entryPlan.value = EntryPlan(
      long: EntryLeg(
        exchange: longEx,
        symbol: longInstr.symbol,
        side: OrderSide.buy,
        qty: longQty,
        price: prices.longPrice,
        minQty: longInstr.minQty ?? longQty,
        refPrice: longMid,
        invalidReason: _legInvalidReason(longEx, longQty),
      ),
      short: EntryLeg(
        exchange: shortEx,
        symbol: shortInstr.symbol,
        side: OrderSide.sell,
        qty: shortQty,
        price: prices.shortPrice,
        minQty: shortInstr.minQty ?? shortQty,
        refPrice: shortMid,
        invalidReason: _legInvalidReason(shortEx, shortQty),
      ),
    );
  }

  String? _legInvalidReason(ExchangeId exchange, double qty) {
    if (_entryController.executorFor(exchange) == null) {
      return 'нет активной сессии';
    }
    if (qty <= 0) return 'объём ниже минимума биржи';
    return null;
  }

  /// Runs the zero-risk preflight canary on the current plan.
  Future<void> runCanary() async {
    final plan = _entryPlan.value;
    if (plan == null || _entryBusy.value) return;
    _entryBusy.value = true;
    _canaryReport.value = null;
    try {
      _canaryReport.value = await _entryController.runCanary(plan);
    } finally {
      _entryBusy.value = false;
    }
  }

  /// Executes the symmetric entry for the current plan.
  Future<void> executeEntry() async {
    final plan = _entryPlan.value;
    if (plan == null || !plan.valid || _entryBusy.value) return;
    _entryBusy.value = true;
    _entryReport.value = null;
    try {
      _entryReport.value =
          await _entryController.execute(plan, leverage: _leverage.value);
    } finally {
      _entryBusy.value = false;
    }
  }

  /// Walks each leg's latest depth snapshot with the sized quantity to estimate
  /// fill coverage and slippage. The long leg buys (crosses asks), the short
  /// leg sells (crosses bids).
  void _updateFills(bool leg1IsLong) {
    final q1 = _quote1.value;
    final q2 = _quote2.value;
    final lev = _leverage.value;
    final cap1 = double.tryParse(capital1Controller.text) ?? 0;
    final cap2 = double.tryParse(capital2Controller.text) ?? 0;

    _fill1.value = (_book1 != null && q1 != null && q1.mid > 0)
        ? simulateFill(
            book: _book1!,
            qtyBase: cap1 * lev / q1.mid,
            isBuy: leg1IsLong,
            referencePrice: q1.mid,
          )
        : null;
    _fill2.value = (_book2 != null && q2 != null && q2.mid > 0)
        ? simulateFill(
            book: _book2!,
            qtyBase: cap2 * lev / q2.mid,
            isBuy: !leg1IsLong,
            referencePrice: q2.mid,
          )
        : null;
  }
}

ArbitrageCalculatorWm arbitrageCalculatorWmFactory({
  required BuildContext context,
}) {
  return ArbitrageCalculatorWm(
    ArbitrageCalculatorModel(),
    registry: context.read<MarketDataRegistry>(),
    feeStore: context.read<FeeSettingsStore>(),
    entryController: ArbitrageEntryController(
      context.read<TradeExecutorRegistry>(),
    ),
  );
}
