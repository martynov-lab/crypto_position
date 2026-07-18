import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:flutter/foundation.dart';

/// App-scoped catalog of the public market-data providers, plus which
/// exchanges are currently connected (have saved credentials).
class MarketDataRegistry {
  final Map<ExchangeId, MarketDataProvider> _providers;
  final Map<ExchangeId, ValueListenable<bool>> _connectedFlags;

  MarketDataRegistry({
    required Map<ExchangeId, MarketDataProvider> providers,
    required Map<ExchangeId, ValueListenable<bool>> connectedFlags,
  }) : _providers = providers,
       _connectedFlags = connectedFlags;

  MarketDataProvider? provider(ExchangeId exchange) => _providers[exchange];

  /// Rebuilds callers when any exchange's connection state changes.
  Listenable get connectedListenable =>
      Listenable.merge(_connectedFlags.values.toList());

  /// Connected exchanges, in [ExchangeId] declaration order.
  List<ExchangeId> get connected => ExchangeId.values
      .where((e) => _connectedFlags[e]?.value ?? false)
      .toList();
}
