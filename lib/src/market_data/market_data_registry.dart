import 'dart:async';

import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:flutter/foundation.dart';

/// App-scoped catalog of the public market-data providers, plus which
/// exchanges are currently connected (have saved credentials).
class MarketDataRegistry {
  /// How long a fetched perp catalog is reused. Listings change on the order of
  /// days, and the arbitrage screens rebuild the catalog on every open — a
  /// coin tapped in the screener would otherwise cost one full instrument
  /// download per exchange per tap.
  static const _catalogTtl = Duration(minutes: 30);

  final Map<ExchangeId, MarketDataProvider> _providers;
  final Map<ExchangeId, ValueListenable<bool>> _connectedFlags;

  /// In-flight or completed catalog fetches, with when each was started. A
  /// failed fetch evicts itself so the next caller retries.
  final _catalogs = <ExchangeId, Future<List<PerpInstrument>>>{};
  final _catalogFetchedAt = <ExchangeId, DateTime>{};

  MarketDataRegistry({
    required Map<ExchangeId, MarketDataProvider> providers,
    required Map<ExchangeId, ValueListenable<bool>> connectedFlags,
  }) : _providers = providers,
       _connectedFlags = connectedFlags;

  MarketDataProvider? provider(ExchangeId exchange) => _providers[exchange];

  /// [exchange]'s linear perpetuals, cached for [_catalogTtl] and shared
  /// between concurrent callers. Throws whatever the provider throws.
  Future<List<PerpInstrument>> instruments(ExchangeId exchange) {
    final provider = _providers[exchange];
    if (provider == null) return Future.value(const []);
    final startedAt = _catalogFetchedAt[exchange];
    final cached = _catalogs[exchange];
    if (cached != null &&
        startedAt != null &&
        DateTime.now().difference(startedAt) < _catalogTtl) {
      return cached;
    }
    final fetch = provider.fetchPerpInstruments();
    _catalogs[exchange] = fetch;
    _catalogFetchedAt[exchange] = DateTime.now();
    // Don't cache a failure: drop it so the next open tries again. The error
    // still reaches the caller awaiting `fetch`.
    unawaited(
      fetch.then((_) {}, onError: (Object _) {
        if (_catalogs[exchange] == fetch) {
          _catalogs.remove(exchange);
          _catalogFetchedAt.remove(exchange);
        }
      }),
    );
    return fetch;
  }

  /// Rebuilds callers when any exchange's connection state changes.
  Listenable get connectedListenable =>
      Listenable.merge(_connectedFlags.values.toList());

  /// Connected exchanges, in [ExchangeId] declaration order.
  List<ExchangeId> get connected => ExchangeId.values
      .where((e) => _connectedFlags[e]?.value ?? false)
      .toList();

  /// All exchanges with a market-data provider, in [ExchangeId] declaration
  /// order. Public market data needs no credentials, so this is wider than
  /// [connected].
  List<ExchangeId> get all =>
      ExchangeId.values.where(_providers.containsKey).toList();
}
