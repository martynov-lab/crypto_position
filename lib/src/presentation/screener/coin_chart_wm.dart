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

  /// Chart timeframe as a bucket size in ms; 0 = raw (per-sample).
  final _bucketMs = ValueNotifier<int>(0);

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

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _controller = _service.watchInstrument(
      instrument,
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
