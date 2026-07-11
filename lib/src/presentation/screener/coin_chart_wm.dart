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

  late final SpreadChartController _controller;
  final _capExceeded = ValueNotifier<bool>(false);

  CoinChartWm(
    super.model, {
    required ScreenerService service,
    required this.instrument,
  }) : _service = service;

  ValueListenable<List<SpreadPoint>> get points => _controller.points;
  ValueListenable<bool> get capExceeded => _capExceeded;
  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;

  int get windowMs => _controller.windowMs;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _controller = _service.watchInstrument(instrument);
    _capExceeded.value = !_controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _capExceeded.dispose();
    super.dispose();
  }
}

CoinChartWm coinChartWmFactory({
  required BuildContext context,
  required Instrument instrument,
}) {
  return CoinChartWm(
    CoinChartModel(),
    service: context.read<ScreenerService>(),
    instrument: instrument,
  );
}
