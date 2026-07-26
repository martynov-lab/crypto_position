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
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
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
const kTimeframesMin = <int>[1, 5, 15];

/// Poll cadences per data kind. Only the quote moves the chart, so it is the
/// only one that needs to be fast: funding is settled hourly at best, and the
/// depth snapshot only feeds the fill estimate and the entry plan.
const _quoteInterval = Duration(seconds: 2);
const _bookInterval = Duration(seconds: 10);
const _fundingInterval = Duration(minutes: 1);

/// Cap on retained raw (2s) samples (~3h). Bounds memory; the display buckets
/// these by the selected timeframe, so history survives timeframe switches.
const _maxSamples = 5400;

/// How many 1-minute candles seed the chart on selection (one hour of history).
const _seedCandles = 300;

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
  // Seeded from the tapped screener signal's entry spread when available (see
  // _applyInitialSelection); otherwise starts blank.
  final entrySpreadController = TextEditingController();
  // Flat default: the spread level at which the pair is expected to converge
  // and the position gets closed.
  final exitSpreadController = TextEditingController(text: '0.5');

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

  /// Timestamp where the seeded candle history ends and the live ask→bid
  /// samples begin, or null before the seed lands. The two are measured
  /// differently (see [spreadHistory]), so the chart marks the seam.
  final _historyEndsMs = ValueNotifier<int?>(null);

  final _dataError = ValueNotifier<String?>(null);
  final _catalogLoading = ValueNotifier<bool>(false);

  // Latest depth snapshots, kept for the fill simulation in [calculate].
  OrderBook? _book1;
  OrderBook? _book2;

  /// Which leg is the buy (cheaper) side, locked once when the pair is selected
  /// so the whole chart shares one orientation. Locking matters: recomputing it
  /// per sample would force the spread positive forever and hide the moment the
  /// venues invert, which is exactly what the trader needs to see.
  final _buyIsExchange1 = ValueNotifier<bool?>(null);

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

  Timer? _quoteTimer;
  Timer? _bookTimer;
  Timer? _fundingTimer;
  int _pollGen = 0;

  /// Widget-provided initial selection is applied at most once, so a catalog
  /// reload can't override what the user changed by hand.
  bool _initialSelectionApplied = false;

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
  ValueListenable<int?> get historyEndsMs => _historyEndsMs;
  ValueListenable<String?> get dataError => _dataError;
  ValueListenable<bool> get catalogLoading => _catalogLoading;
  ValueListenable<ArbitrageResult?> get result => _result;
  ValueListenable<FillEstimate?> get fill1 => _fill1;
  ValueListenable<FillEstimate?> get fill2 => _fill2;
  ValueListenable<bool?> get buyIsExchange1 => _buyIsExchange1;
  ValueListenable<EntryPlan?> get entryPlan => _entryPlan;

  /// The venue to buy on (the cheaper one when the pair was selected), or null
  /// before the orientation is locked.
  ExchangeId? get buyExchange => switch (_buyIsExchange1.value) {
    true => _exchange1.value,
    false => _exchange2.value,
    null => null,
  };

  /// The venue to sell on (the dearer one when the pair was selected).
  ExchangeId? get sellExchange => switch (_buyIsExchange1.value) {
    true => _exchange2.value,
    false => _exchange1.value,
    null => null,
  };
  ValueListenable<CanaryReport?> get canaryReport => _canaryReport;
  ValueListenable<EntryReport?> get entryReport => _entryReport;
  ValueListenable<bool> get entryBusy => _entryBusy;
  Listenable get connectedListenable => _registry.connectedListenable;

  /// Current spread of the sell leg over the buy leg, or null before the first
  /// sample. Positive while the pair still favours the original direction.
  double? get currentSpreadPct =>
      _spreadSeries.value.isEmpty ? null : _spreadSeries.value.last.spreadPct;

  /// All exchanges with market data (regardless of the selected coin).
  List<ExchangeId> get availableExchangesAll => _registry.all;

  /// True when the coin was handed in (screener) rather than searched for, so
  /// the search field is pointless — the venue pickers still work.
  bool get coinFixed => widget.initialBase != null;

  /// Exchanges offering [selectedBase]. Public market data needs no
  /// credentials; the trade layer checks for a live session on its own.
  List<ExchangeId> get availableExchanges {
    final base = _selectedBase.value;
    if (base == null) return const [];
    final covering = _basesToExchanges[base] ?? const {};
    return _registry.all.where(covering.contains).toList();
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
            (_quoteTimer == null || !_quoteTimer!.isActive)) {
          _startTimers();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _cancelTimers();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
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
    _historyEndsMs.dispose();
    _dataError.dispose();
    _catalogLoading.dispose();
    _result.dispose();
    _fill1.dispose();
    _fill2.dispose();
    _buyIsExchange1.dispose();
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
    final errors = <String>[];
    for (final exchange in _registry.all) {
      try {
        final instruments = await _registry.instruments(exchange);
        final byBase = <String, PerpInstrument>{};
        for (final ins in instruments) {
          byBase[ins.base] = ins;
          _basesToExchanges.putIfAbsent(ins.base, () => {}).add(exchange);
        }
        _byExchange[exchange] = byBase;
      } on Object catch (e) {
        errors.add('${exchange.label}: $e');
      }
    }
    if (errors.isNotEmpty) _dataError.value = errors.join('\n');
    _catalogLoading.value = false;
    _recomputeCandidates();
    _applyInitialSelection();
  }

  /// Applies the widget's pre-selected coin/venues (screener signal) once the
  /// catalog knows which exchanges cover the coin. Falls back to the first
  /// available venues when a requested one doesn't cover the coin.
  void _applyInitialSelection() {
    if (_initialSelectionApplied) return;
    final base = widget.initialBase;
    if (base == null) return;
    if (!(_basesToExchanges[base]?.isNotEmpty ?? false)) return;
    _initialSelectionApplied = true;
    _selectedBase.value = base;
    searchController.text = base;
    _candidates.value = const [];
    final available = availableExchanges;
    final picks = <ExchangeId>[];
    for (final e in [
      widget.initialExchange1,
      widget.initialExchange2,
      ...available,
    ]) {
      if (e != null && available.contains(e) && !picks.contains(e)) {
        picks.add(e);
      }
    }
    _exchange1.value = picks.isNotEmpty ? picks[0] : null;
    _exchange2.value = picks.length > 1 ? picks[1] : null;
    final entrySpreadPct = widget.initialEntrySpreadPct;
    if (entrySpreadPct != null) {
      entrySpreadController.text = _fmtSpreadInput(entrySpreadPct);
    }
    _restartPolling();
    // The signal says which venue to buy on, so the chart must not re-derive it
    // from prices: a signal fired on a pair that has since inverted would draw
    // upside down relative to the card the user tapped. Set after the restart,
    // which clears the orientation. Only when the requested leg survived the
    // availability narrowing above — otherwise the pair isn't the signal's.
    final long = widget.initialExchange1;
    if (long != null) {
      if (_exchange1.value == long) {
        _buyIsExchange1.value = true;
      } else if (_exchange2.value == long) {
        _buyIsExchange1.value = false;
      }
    }
  }

  /// Formats a percent number for the entry/exit spread fields, trimming
  /// trailing zeros (e.g. `0.82`, not `0.820000`).
  static String _fmtSpreadInput(double pct) {
    var s = pct.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  void _recomputeCandidates() {
    final query = searchController.text.trim().toUpperCase();
    // Hide the list once a base is locked in (text equals the selection).
    if (query.isEmpty || query == _selectedBase.value) {
      _candidates.value = const [];
      return;
    }
    final matches =
        _basesToExchanges.keys.where((b) => b.contains(query)).toList()
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

  /// Selection changed: wipe the live data and start a fresh trace. Everything
  /// collected for the previous pair is dropped here — nothing keeps running
  /// for a coin or venue that is no longer on screen.
  void _restartPolling() {
    _cancelTimers();
    _quote1.value = null;
    _quote2.value = null;
    _funding1.value = null;
    _funding2.value = null;
    _spreadSeries.value = const [];
    _historyEndsMs.value = null;
    _result.value = null;
    _fill1.value = null;
    _fill2.value = null;
    _book1 = null;
    _book2 = null;
    _buyIsExchange1.value = null;
    _entryPlan.value = null;
    _canaryReport.value = null;
    _entryReport.value = null;
    _dataError.value = null;

    if (!_hasValidSelection) return;
    _startTimers();
  }

  /// Kicks off an immediate poll of each data kind plus its periodic timer,
  /// keeping any existing chart history intact (used on start and on foreground
  /// resume).
  void _startTimers() {
    _cancelTimers();
    final gen = ++_pollGen;
    unawaited(_seedSpreadHistory(gen));
    unawaited(_pollQuotes(gen));
    unawaited(_pollBooks(gen));
    unawaited(_pollFunding(gen));
    _quoteTimer = Timer.periodic(_quoteInterval, (_) => _pollQuotes(gen));
    _bookTimer = Timer.periodic(_bookInterval, (_) => _pollBooks(gen));
    _fundingTimer = Timer.periodic(_fundingInterval, (_) => _pollFunding(gen));
  }

  void _cancelTimers() {
    _quoteTimer?.cancel();
    _bookTimer?.cancel();
    _fundingTimer?.cancel();
    _quoteTimer = null;
    _bookTimer = null;
    _fundingTimer = null;
  }

  /// Locks the buy/sell orientation the first time both prices are known, so
  /// the cheaper venue becomes the buy leg and the spread starts positive.
  /// Equal prices leave it unlocked — there is no meaningful direction yet.
  void _lockOrientation(double mid1, double mid2) {
    if (_buyIsExchange1.value != null) return;
    if (mid1 <= 0 || mid2 <= 0 || mid1 == mid2) return;
    _buyIsExchange1.value = mid1 < mid2;
  }

  /// Backfills the spread chart from both venues' recent candles so the graph
  /// is populated immediately instead of filling in over minutes of polling.
  /// Seeded points are older than any live sample, so they are prepended to
  /// whatever the concurrent poll has already collected.
  Future<void> _seedSpreadHistory(int gen) async {
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
      final series = await Future.wait([
        p1.fetchKlines(sym1, limit: _seedCandles),
        p2.fetchKlines(sym2, limit: _seedCandles),
      ]);
      if (gen != _pollGen) return; // selection changed mid-flight
      // Lock from the newest candles so history shares the live orientation.
      if (series[0].isNotEmpty && series[1].isNotEmpty) {
        _lockOrientation(series[0].last.close, series[1].last.close);
      }
      final buyIs1 = _buyIsExchange1.value ?? true;
      final points = spreadHistory(
        buyIs1 ? series[0] : series[1],
        buyIs1 ? series[1] : series[0],
      );
      if (points.isEmpty) return;

      final seeded = [
        for (final p in points) SpreadSample(p.tsMs, p.spreadPct),
      ];
      // Keep only live samples newer than the seeded history to avoid overlap.
      final lastSeededTs = seeded.last.tsMs;
      final live = _spreadSeries.value
          .where((s) => s.tsMs > lastSeededTs)
          .toList();
      _spreadSeries.value = [...seeded, ...live];
      _historyEndsMs.value = lastSeededTs;
    } on Object {
      // History is a nicety — a failure just leaves the chart to fill live.
    }
  }

  /// The current pair's per-leg (provider, symbol) pairs, or null while the
  /// selection is incomplete or the catalog doesn't cover it.
  ({MarketDataProvider p1, String sym1, MarketDataProvider p2, String sym2})?
  get _legs {
    final base = _selectedBase.value;
    final e1 = _exchange1.value;
    final e2 = _exchange2.value;
    if (base == null || e1 == null || e2 == null) return null;
    final sym1 = _byExchange[e1]?[base]?.symbol;
    final sym2 = _byExchange[e2]?[base]?.symbol;
    final p1 = _registry.provider(e1);
    final p2 = _registry.provider(e2);
    if (sym1 == null || sym2 == null || p1 == null || p2 == null) return null;
    return (p1: p1, sym1: sym1, p2: p2, sym2: sym2);
  }

  /// Quotes — the fast loop: appends one chart sample per poll and refreshes
  /// the entry plan.
  Future<void> _pollQuotes(int gen) async {
    final legs = _legs;
    if (legs == null) return;
    try {
      final quotes = await Future.wait([
        legs.p1.fetchQuote(legs.sym1),
        legs.p2.fetchQuote(legs.sym2),
      ]);
      if (gen != _pollGen) return; // selection changed mid-flight
      final q1 = quotes[0];
      final q2 = quotes[1];
      _quote1.value = q1;
      _quote2.value = q2;
      _dataError.value = null;

      _lockOrientation(q1.mid, q2.mid);
      final buyIs1 = _buyIsExchange1.value ?? true;
      final spreadPct = executableSpreadPct(
        buy: buyIs1 ? q1 : q2,
        sell: buyIs1 ? q2 : q1,
      );
      if (spreadPct != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final list = [..._spreadSeries.value, SpreadSample(now, spreadPct)];
        if (list.length > _maxSamples) {
          list.removeRange(0, list.length - _maxSamples);
        }
        _spreadSeries.value = list;
      }

      _refreshPlanAndFills();
    } on Object catch (e) {
      if (gen != _pollGen) return;
      _dataError.value = e.toString();
    }
  }

  /// Depth snapshots — only the fill estimate and the entry plan read these,
  /// so they lag the quotes without affecting the chart.
  Future<void> _pollBooks(int gen) async {
    final legs = _legs;
    if (legs == null) return;
    try {
      final books = await Future.wait([
        legs.p1.fetchOrderBook(legs.sym1),
        legs.p2.fetchOrderBook(legs.sym2),
      ]);
      if (gen != _pollGen) return;
      _book1 = books[0];
      _book2 = books[1];
      _refreshPlanAndFills();
    } on Object catch (e) {
      if (gen != _pollGen) return;
      _dataError.value = e.toString();
    }
  }

  /// Funding — the slow loop: the rate is settled hourly at best, so polling it
  /// with the quotes was pure waste.
  Future<void> _pollFunding(int gen) async {
    final legs = _legs;
    if (legs == null) return;
    try {
      final funding = await Future.wait([
        legs.p1.fetchFunding(legs.sym1),
        legs.p2.fetchFunding(legs.sym2),
      ]);
      if (gen != _pollGen) return;
      _funding1.value = funding[0];
      _funding2.value = funding[1];
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
    if (e1 == null ||
        e2 == null ||
        q1 == null ||
        q2 == null ||
        f1 == null ||
        f2 == null) {
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
      leg1IsLong: _leg1IsLong,
    );
    _result.value = computeArbitrage(input);
    // A new calculation invalidates any prior canary / entry outcome.
    _canaryReport.value = null;
    _entryReport.value = null;
    _updateFills(input.leg1IsLong);
    _buildEntryPlan(input.leg1IsLong);
  }

  /// Keeps the fill estimate and the entry plan live from each poll, so both
  /// panels are usable as soon as a coin and its two venues are picked —
  /// "Рассчитать" is only needed for the profit projection. Skipped while an
  /// order is in flight so the plan can't shift under a running entry.
  void _refreshPlanAndFills() {
    if (_entryBusy.value) return;
    if (_quote1.value == null || _quote2.value == null) return;
    _updateFills(_leg1IsLong);
    _buildEntryPlan(_leg1IsLong);
  }

  /// Which leg the plan goes long: the orientation the chart locked when the
  /// pair was selected (or the one the screener signal pinned), so the order
  /// preview can't contradict the line the user is looking at. Falls back to
  /// the cheaper leg while the orientation is still unlocked.
  bool get _leg1IsLong {
    final locked = _buyIsExchange1.value;
    if (locked != null) return locked;
    final mid1 = _quote1.value?.mid ?? 0;
    final mid2 = _quote2.value?.mid ?? 0;
    return mid1 <= mid2;
  }

  /// Builds the two-leg entry plan (sizes, limit prices, per-leg validity) from
  /// the current selection, quotes and instrument filters. Cleared when the
  /// selection is incomplete or an instrument is missing.
  void _buildEntryPlan(bool leg1IsLong) {
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
        double.tryParse(
          (leg1IsLong ? capital1Controller : capital2Controller).text,
        ) ??
        0;
    final shortCap =
        double.tryParse(
          (leg1IsLong ? capital2Controller : capital1Controller).text,
        ) ??
        0;
    final longInstr = _byExchange[longEx]?[base];
    final shortInstr = _byExchange[shortEx]?[base];
    final shortMid = (leg1IsLong ? q2 : q1).mid;
    if (longInstr == null ||
        shortInstr == null ||
        longMid <= 0 ||
        shortMid <= 0) {
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

    final longCanary = canaryOrder(
      refPrice: longMid,
      isBuy: true,
      tickSize: longInstr.tickSize,
      qtyStep: longInstr.qtyStep,
      minQty: longInstr.minQty,
      minNotional: longInstr.minNotional,
      contractSize: longInstr.contractSize ?? 1,
    );
    final shortCanary = canaryOrder(
      refPrice: shortMid,
      isBuy: false,
      tickSize: shortInstr.tickSize,
      qtyStep: shortInstr.qtyStep,
      minQty: shortInstr.minQty,
      minNotional: shortInstr.minNotional,
      contractSize: shortInstr.contractSize ?? 1,
    );

    _entryPlan.value = EntryPlan(
      long: EntryLeg(
        exchange: longEx,
        symbol: longInstr.symbol,
        side: OrderSide.buy,
        qty: longQty,
        price: prices.longPrice,
        canaryQty: longCanary.qty,
        canaryPrice: longCanary.price,
        refPrice: longMid,
        contractSize: longInstr.contractSize ?? 1,
        invalidReason: _legInvalidReason(
          longEx,
          longQty,
          prices.longPrice,
          longInstr,
        ),
      ),
      short: EntryLeg(
        exchange: shortEx,
        symbol: shortInstr.symbol,
        side: OrderSide.sell,
        qty: shortQty,
        price: prices.shortPrice,
        canaryQty: shortCanary.qty,
        canaryPrice: shortCanary.price,
        refPrice: shortMid,
        contractSize: shortInstr.contractSize ?? 1,
        invalidReason: _legInvalidReason(
          shortEx,
          shortQty,
          prices.shortPrice,
          shortInstr,
        ),
      ),
    );
  }

  String? _legInvalidReason(
    ExchangeId exchange,
    double qty,
    double price,
    PerpInstrument instrument,
  ) {
    if (_entryController.executorFor(exchange) == null) {
      return 'нет активной сессии';
    }
    if (qty <= 0) return 'объём ниже минимума биржи';
    // Exchanges also enforce a minimum order value, so a valid quantity can
    // still be rejected when the capital is too small.
    final minNotional = instrument.minNotional;
    if (minNotional != null) {
      final notional = qty * price * (instrument.contractSize ?? 1);
      if (notional < minNotional) {
        return 'сумма ордера ${notional.toStringAsFixed(2)} < минимума '
            '${minNotional.toStringAsFixed(0)} USDT — увеличьте капитал/плечо';
      }
    }
    return null;
  }

  /// Runs the zero-risk preflight canary on the current plan.
  Future<void> runCanary() async {
    final plan = _entryPlan.value;
    if (plan == null || _entryBusy.value) return;
    _entryBusy.value = true;
    _canaryReport.value = null;
    try {
      _canaryReport.value =
          await _entryController.runCanary(plan, leverage: _leverage.value);
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
      _entryReport.value = await _entryController.execute(
        plan,
        leverage: _leverage.value,
      );
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
      context.read<ExchangeAccountRegistry>(),
    ),
  );
}
