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

/// Owns one coin's live spread-chart watch: opens it on init, tears it down
/// (sends `unwatch`) on dispose.
class CoinChartWm extends WidgetModel<CoinChartScreen, CoinChartModel> {
  final ScreenerService _service;
  final Instrument instrument;
  final String? longExchange;
  final String? shortExchange;

  late final SpreadChartController _controller;
  final _capExceeded = ValueNotifier<bool>(false);

  /// Chart timeframe as a bucket size in ms (same options as the calculator,
  /// [kTimeframesMin]); 0 = raw (per-sample).
  final _bucketMs = ValueNotifier<int>(kTimeframesMin.first * 60000);

  /// Requested history window (3h) — enough raw samples for the largest
  /// timeframe to still draw a line (matches the calculator's retention).
  static const _windowMs = 10800000;

  CoinChartWm(
    super.model, {
    required ScreenerService service,
    required this.instrument,
    this.longExchange,
    this.shortExchange,
  }) : _service = service;

  ValueListenable<List<SpreadPoint>> get points => _controller.points;
  ValueListenable<WatchMeta?> get meta => _controller.meta;
  ValueListenable<bool> get capExceeded => _capExceeded;
  ValueListenable<int> get bucketMs => _bucketMs;
  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;

  int get windowMs => _controller.windowMs;

  void setTimeframe(int bucketMs) => _bucketMs.value = bucketMs;

  /// `GET /spread/range` for this instrument — up to several days of
  /// per-minute min/max/close, for the "3 days" view.
  Future<Result<SpreadRange, Object>> fetchSpreadRange() =>
      _service.fetchSpreadRange(instrument);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _controller = _service.watchInstrument(
      instrument,
      windowMs: _windowMs,
      longExchange: longExchange,
      shortExchange: shortExchange,
    );
    _capExceeded.value = !_controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _capExceeded.dispose();
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
