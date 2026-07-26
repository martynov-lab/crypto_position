import 'dart:async';

import 'package:core/core.dart';
import 'package:crypto_position/src/favorites/favorite_coins_store.dart';
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
  final FavoriteCoinsStore _favorites;

  /// A signal freezes the spread of the moment it fired, so the cards would
  /// keep showing a number that has long moved on. `/summary` is the only
  /// all-coins live source (the WS chart watch is capped at 3 instruments), so
  /// poll it while the screen is on to keep "вход сейчас" current.
  static const _summaryPollInterval = Duration(seconds: 10);

  Timer? _summaryTimer;

  ScreenerScreenWm(
    super.model, {
    required ScreenerService service,
    required FavoriteCoinsStore favorites,
  })  : _service = service,
        _favorites = favorites;

  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;
  ValueListenable<List<SignalEvent>> get signals => _service.signals;
  ValueListenable<List<SummaryEntry>> get summary => _service.summary;
  ValueListenable<List<InstrumentCoverage>> get universe => _service.universe;
  ValueListenable<String?> get error => _service.error;

  /// Rebuild trigger for filter-dependent views (the universe tab narrows to
  /// the enabled venues).
  Listenable get filters => _service.effectiveConfig;

  ClientConfig get clientConfig => _service.clientConfig;

  /// Rebuild trigger for the starred coins; read the flags via [isFavorite].
  Listenable get favorites => _favorites;

  bool isFavorite(String pair) => _favorites.isFavorite(pair);

  void toggleFavorite(String pair) => _favorites.toggle(pair);

  /// Exchanges currently switched on in the filters (all of them when the
  /// config leaves `exchanges` unset).
  Set<String> get enabledExchanges =>
      {...clientConfig.exchanges ?? ScreenerDefaults.allExchanges};

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_service.refreshSummary());
    _summaryTimer = Timer.periodic(
      _summaryPollInterval,
      (_) => unawaited(_service.refreshSummary()),
    );
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }

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
    favorites: context.read<FavoriteCoinsStore>(),
  );
}
