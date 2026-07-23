import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:exchange/exchange.dart';

/// App-scoped lookup of the live [ExchangeAccountRepository] per exchange —
/// lets the trade layer check available balance before risking an entry,
/// reusing the same repositories the positions/home screens already keep
/// live over each exchange's account WS stream.
class ExchangeAccountRegistry {
  final Map<ExchangeId, ExchangeAccountRepository? Function()> _resolvers;

  ExchangeAccountRegistry(this._resolvers);

  /// The current repository for [exchange], or null when that exchange has
  /// no active authenticated session.
  ExchangeAccountRepository? repository(ExchangeId exchange) =>
      _resolvers[exchange]?.call();
}
