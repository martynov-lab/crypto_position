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

  /// Minimum order-size increment, in base units (or contracts where the
  /// exchange sizes orders in contracts). Null when the exchange didn't report
  /// it. Used to round order quantities to a value the exchange will accept.
  final double? qtyStep;

  /// Minimum order size, same unit as [qtyStep]. Null when unknown.
  final double? minQty;

  /// Minimum price increment. Null when unknown. Used to round limit prices.
  final double? tickSize;

  /// Value of one contract in base units. `1` (or null) for exchanges that
  /// size orders directly in the base asset; >1 (e.g. Gate `quanto_multiplier`)
  /// where one contract represents a fixed amount of the base asset.
  final double? contractSize;

  /// Minimum order value in quote currency (USDT). Exchanges reject orders
  /// worth less than this even when the quantity clears [minQty]. Null when the
  /// exchange doesn't report one.
  final double? minNotional;

  const PerpInstrument({
    required this.exchange,
    required this.symbol,
    required this.base,
    required this.quote,
    this.qtyStep,
    this.minQty,
    this.tickSize,
    this.contractSize,
    this.minNotional,
  });

  String get pair => '$base/$quote';
}

/// One side's price level in an order book.
class BookLevel {
  final double price;

  /// Resting size at [price], in base units (implementations convert from
  /// contracts using [PerpInstrument.contractSize] where needed).
  final double size;

  const BookLevel(this.price, this.size);
}

/// A depth snapshot for one instrument. [bids] descend from the best (highest)
/// bid; [asks] ascend from the best (lowest) ask.
class OrderBook {
  final List<BookLevel> bids;
  final List<BookLevel> asks;

  const OrderBook({required this.bids, required this.asks});
}

/// One historical candle. Only the close is kept — the spread history needs a
/// single price per bucket.
class Candle {
  /// Candle open time, epoch ms.
  final int tsMs;
  final double close;

  const Candle(this.tsMs, this.close);
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

  /// Order-book depth for [symbol]: up to [depth] levels per side, sizes
  /// normalized to base units. A snapshot — callers must treat it as an
  /// estimate, not a guarantee of fill.
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50});

  /// Recent candles for [symbol], oldest first, used to seed the spread chart
  /// with history instead of waiting for live samples to accumulate.
  /// [intervalMinutes] is 1, 5 or 15; [limit] caps the number of candles.
  Future<List<Candle>> fetchKlines(
    String symbol, {
    int intervalMinutes = 1,
    int limit = 60,
  });
}
