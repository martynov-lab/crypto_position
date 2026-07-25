import 'dart:async';

import 'package:core/core.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart'
    show kTimeframesMin;
import 'package:crypto_position/src/presentation/screener/coin_chart_model.dart';
import 'package:crypto_position/src/presentation/screener/coin_chart_screen.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:network/network.dart';
import 'package:provider/provider.dart';
import 'package:screener/screener.dart';

/// The long/short pair the chart is pinned to. Both null = the server picks
/// the best pair (how the screen opens from the universe catalog).
typedef PinnedPair = ({String? long, String? short});

/// Owns one coin's live spread-chart watch: opens it on init, re-pins it when
/// the user picks another venue pair, tears it down (sends `unwatch`) on
/// dispose.
class CoinChartWm extends WidgetModel<CoinChartScreen, CoinChartModel> {
  final ScreenerService _service;
  final Instrument instrument;

  late final SpreadChartController _controller;
  final _capExceeded = ValueNotifier<bool>(false);
  final _pinned = ValueNotifier<PinnedPair>((long: null, short: null));

  /// True when no `watch_snapshot` arrived within [_noDataTimeout] — the coin
  /// has no live spread right now (fewer than two quoting venues), which the
  /// server reports as a one-shot error without an instrument to match on.
  final _noData = ValueNotifier<bool>(false);
  Timer? _noDataTimer;

  /// Chart timeframe as a bucket size in ms (same options as the calculator,
  /// [kTimeframesMin]); 0 = raw (per-sample).
  final _bucketMs = ValueNotifier<int>(kTimeframesMin.first * 60000);

  /// Requested history window (3h) — enough raw samples for the largest
  /// timeframe to still draw a line (matches the calculator's retention).
  static const _windowMs = 10800000;

  static const _noDataTimeout = Duration(seconds: 12);

  CoinChartWm(
    super.model, {
    required ScreenerService service,
    required this.instrument,
    String? longExchange,
    String? shortExchange,
  }) : _service = service {
    _pinned.value = (long: longExchange, short: shortExchange);
  }

  ValueListenable<List<SpreadPoint>> get points => _controller.points;
  ValueListenable<WatchMeta?> get meta => _controller.meta;
  ValueListenable<bool> get capExceeded => _capExceeded;
  ValueListenable<bool> get noData => _noData;
  ValueListenable<int> get bucketMs => _bucketMs;
  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;

  /// The pair the chart is currently pinned to: the caller's pick, or the one
  /// the server chose (from the first snapshot) when it opened unpinned.
  ValueListenable<PinnedPair> get pinned => _pinned;

  int get windowMs => _controller.windowMs;

  /// Venues that list this coin (screener catalog), narrowed to the exchanges
  /// enabled in the filters — the options for the long/short pickers. Empty
  /// when the catalog has not arrived yet.
  List<String> get venues {
    final enabled = {
      ..._service.clientConfig.exchanges ?? ScreenerDefaults.allExchanges,
    };
    for (final row in _service.universe.value) {
      if (row.pair != instrument.pair) continue;
      return row.exchanges.where(enabled.contains).toList();
    }
    return const [];
  }

  void setTimeframe(int bucketMs) => _bucketMs.value = bucketMs;

  /// Re-pins the chart (and the calculator below it) to another venue pair.
  /// A leg still unset (the first pick before the server's snapshot landed)
  /// is filled with another listed venue — the server pins a pair or nothing.
  void repin({String? long, String? short}) {
    final options = venues;
    var newLong = long;
    var newShort = short;
    if (newLong == null && newShort != null) {
      newLong = _otherVenue(options, newShort);
    } else if (newShort == null && newLong != null) {
      newShort = _otherVenue(options, newLong);
    }
    if (newLong == null || newShort == null) return;
    if (_pinned.value.long == newLong && _pinned.value.short == newShort) {
      return;
    }
    _pinned.value = (long: newLong, short: newShort);
    _controller.repin(longExchange: newLong, shortExchange: newShort);
    _armNoDataTimer();
  }

  static String? _otherVenue(List<String> venues, String taken) {
    for (final venue in venues) {
      if (venue != taken) return venue;
    }
    return null;
  }

  /// Retries the current pair after a "no live spread" timeout.
  void retry() {
    final pair = _pinned.value;
    _controller.repin(longExchange: pair.long, shortExchange: pair.short);
    _armNoDataTimer();
  }

  /// `GET /spread/range` for this instrument — up to several days of
  /// per-minute min/max/close, for the "3 days" view.
  Future<Result<SpreadRange, Object>> fetchSpreadRange() =>
      _service.fetchSpreadRange(instrument);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    final pair = _pinned.value;
    _controller = _service.watchInstrument(
      instrument,
      windowMs: _windowMs,
      longExchange: pair.long,
      shortExchange: pair.short,
    );
    _capExceeded.value = !_controller.start();
    _controller.meta.addListener(_onMeta);
    if (!_capExceeded.value) _armNoDataTimer();
  }

  /// Adopts the server-picked pair once the first snapshot lands, so the
  /// pickers and the calculator show the pair the chart actually draws.
  void _onMeta() {
    final meta = _controller.meta.value;
    if (meta == null) return;
    _noDataTimer?.cancel();
    _noData.value = false;
    if (_pinned.value.long == null || _pinned.value.short == null) {
      _pinned.value = (long: meta.longExchange, short: meta.shortExchange);
    }
  }

  void _armNoDataTimer() {
    _noData.value = false;
    _noDataTimer?.cancel();
    _noDataTimer = Timer(_noDataTimeout, () {
      if (_controller.meta.value == null) _noData.value = true;
    });
  }

  @override
  void dispose() {
    _noDataTimer?.cancel();
    _controller.meta.removeListener(_onMeta);
    _controller.dispose();
    _capExceeded.dispose();
    _noData.dispose();
    _pinned.dispose();
    _bucketMs.dispose();
    super.dispose();
  }
}

CoinChartWm coinChartWmFactory({
  required BuildContext context,
  required Instrument instrument,
  String? longExchange,
  String? shortExchange,
}) {
  return CoinChartWm(
    CoinChartModel(),
    service: context.read<ScreenerService>(),
    instrument: instrument,
    longExchange: longExchange,
    shortExchange: shortExchange,
  );
}
