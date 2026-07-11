import 'package:core/core.dart';
import 'package:crypto_position/src/presentation/screener/screener_screen.dart';
import 'package:crypto_position/src/presentation/screener/screener_screen_model.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:network/network.dart';
import 'package:provider/provider.dart';
import 'package:screener/screener.dart';

/// Drives the arbitrage screener screen off the app-scoped [ScreenerService].
/// State (signals, universe, connection) lives in the service; this WM only
/// exposes it and forwards config changes.
class ScreenerScreenWm
    extends WidgetModel<ScreenerScreen, ScreenerScreenModel> {
  final ScreenerService _service;

  ScreenerScreenWm(super.model, {required ScreenerService service})
      : _service = service;

  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;
  ValueListenable<List<SignalEvent>> get signals => _service.signals;
  ValueListenable<List<SummaryEntry>> get summary => _service.summary;
  ValueListenable<List<InstrumentCoverage>> get universe => _service.universe;
  ValueListenable<String?> get error => _service.error;

  ClientConfig get clientConfig => _service.clientConfig;

  void applyConfig(ClientConfig config) => _service.reconfigure(config);

  Future<Result<ConfigValidation, Object>> validateConfig(
    ClientConfig config,
  ) =>
      _service.validateConfig(config);

  Future<void> refreshSummary() => _service.refreshSummary();
}

ScreenerScreenWm screenerScreenWmFactory({required BuildContext context}) {
  return ScreenerScreenWm(
    ScreenerScreenModel(),
    service: context.read<ScreenerService>(),
  );
}
