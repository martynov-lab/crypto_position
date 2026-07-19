import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:exchange/exchange.dart';

/// App-scoped lookup of the live [TradeExecutor] per exchange. Executors are
/// owned by the per-exchange account sessions, which come and go with login /
/// logout, so the registry resolves the current one lazily each call rather
/// than holding a stale reference.
class TradeExecutorRegistry {
  final Map<ExchangeId, TradeExecutor? Function()> _resolvers;

  TradeExecutorRegistry(this._resolvers);

  /// The current executor for [exchange], or null when that exchange has no
  /// active authenticated session.
  TradeExecutor? executor(ExchangeId exchange) => _resolvers[exchange]?.call();
}
