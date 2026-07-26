import 'dart:async';

import 'package:core/core.dart';
import 'package:crypto_position/src/favorites/favorite_coins_store.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
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

  /// Venues the app has a market-data provider for. The server screens more
  /// (coinex, kucoin, phemex), but a coin chart is drawn from the exchanges'
  /// own REST — so an opportunity on a venue we can't price is untradable here
  /// and is dropped client-side rather than reconfiguring the (server-wide)
  /// screening config.
  static final _pricedVenues = {for (final e in ExchangeId.values) e.key};

  Timer? _summaryTimer;

  final _signals = ValueNotifier<List<SignalEvent>>(const []);
  final _summary = ValueNotifier<List<SummaryEntry>>(const []);

  ScreenerScreenWm(
    super.model, {
    required ScreenerService service,
    required FavoriteCoinsStore favorites,
  })  : _service = service,
        _favorites = favorites;

  ValueListenable<WsConnectionState> get connectionState =>
      _service.connectionState;

  /// Signals and best-spread rows narrowed to pairs whose both legs sit on a
  /// venue the app can price (see [_pricedVenues]).
  ValueListenable<List<SignalEvent>> get signals => _signals;
  ValueListenable<List<SummaryEntry>> get summary => _summary;
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

  /// Exchanges currently switched on in the filters, narrowed to the ones the
  /// app can price — the catalog hides coins left with fewer than two.
  Set<String> get enabledExchanges =>
      {...clientConfig.exchanges ?? ScreenerDefaults.allExchanges}
          .where(_pricedVenues.contains)
          .toSet();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _service.signals.addListener(_republishSignals);
    _service.summary.addListener(_republishSummary);
    _republishSignals();
    _republishSummary();
    unawaited(_service.refreshSummary());
    _summaryTimer = Timer.periodic(
      _summaryPollInterval,
      (_) => unawaited(_service.refreshSummary()),
    );
  }

  void _republishSignals() {
    _signals.value = _service.signals.value
        .where((event) =>
            _pricedVenues.contains(event.spread.buyExchange) &&
            _pricedVenues.contains(event.spread.sellExchange))
        .toList();
  }

  void _republishSummary() {
    _summary.value = _service.summary.value
        .where((row) =>
            _pricedVenues.contains(row.buyExchange) &&
            _pricedVenues.contains(row.sellExchange))
        .toList();
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    _service.signals.removeListener(_republishSignals);
    _service.summary.removeListener(_republishSummary);
    _signals.dispose();
    _summary.dispose();
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
