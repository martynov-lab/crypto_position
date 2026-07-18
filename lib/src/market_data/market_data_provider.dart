import 'package:crypto_position/src/market_data/exchange_id.dart';

/// One tradable linear perpetual on an exchange.
class PerpInstrument {
  final ExchangeId exchange;

  /// Exchange-native symbol used in API calls (e.g. `BTCUSDT`, `BTC-USDT-SWAP`).
  final String symbol;

  /// Normalized base asset for cross-exchange search/matching (e.g. `BTC`).
  final String base;

  /// Normalized quote asset (e.g. `USDT`).
  final String quote;

  const PerpInstrument({
    required this.exchange,
    required this.symbol,
    required this.base,
    required this.quote,
  });

  String get pair => '$base/$quote';
}

/// A live price snapshot for one instrument.
class Quote {
  final double bid;
  final double ask;
  final double last;

  const Quote({required this.bid, required this.ask, required this.last});

  /// Mid price; falls back to [last] when the book sides are missing.
  double get mid => (bid > 0 && ask > 0) ? (bid + ask) / 2 : last;
}

/// Funding state for one perpetual.
class FundingInfo {
  /// Funding rate as a fraction per interval (e.g. `0.0001` = 0.01%).
  final double rate;

  /// Funding interval in hours (usually 8, 4 or 1).
  final double intervalHours;

  /// Epoch ms of the next funding settlement, or null if unknown.
  final int? nextFundingMs;

  const FundingInfo({
    required this.rate,
    required this.intervalHours,
    this.nextFundingMs,
  });
}

/// Read-only public market data for one exchange. Unauthenticated; each
/// implementation calls the exchange's public REST endpoints.
abstract interface class MarketDataProvider {
  ExchangeId get exchange;

  /// The exchange's linear USDT perpetuals, for coin search. Cached by the
  /// implementation after the first successful fetch.
  Future<List<PerpInstrument>> fetchPerpInstruments();

  /// Best bid/ask/last for [symbol].
  Future<Quote> fetchQuote(String symbol);

  /// Current funding rate, interval and next settlement for [symbol].
  Future<FundingInfo> fetchFunding(String symbol);
}
