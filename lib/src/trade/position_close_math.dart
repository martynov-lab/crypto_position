import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/trade/order_rounding.dart';
import 'package:exchange/exchange.dart';

/// Whether [side] is a long, in whichever wording the exchange reports it
/// (Bybit `Buy`/`Sell`, everyone else `long`/`short`). Returns null when the
/// wording is unknown — the direction must never be guessed, since a wrong
/// guess doubles the position instead of closing it.
bool? positionIsLong(String side) => switch (side.trim().toLowerCase()) {
  'buy' || 'long' => true,
  'sell' || 'short' => false,
  _ => null,
};

/// The order side that closes a position: a long is closed by selling, a short
/// by buying.
OrderSide closeOrderSide({required bool isLong}) =>
    isLong ? OrderSide.sell : OrderSide.buy;

/// Whether [PositionModel.size] has to be divided by the instrument's contract
/// size to reach the unit [TradeExecutor.placeLimitOrder] expects.
///
/// The two units only diverge on exchanges that report a position in the base
/// asset but accept orders in contracts:
/// * Bybit, Bitget — base units on both sides, no conversion;
/// * Gate, MEXC — position size is mapped to base units, orders are contracts;
/// * OKX — position size is already a contract count (`pos`), as are orders.
bool sizeNeedsContractConversion(ExchangeId exchange) => switch (exchange) {
  ExchangeId.gate || ExchangeId.mexc => true,
  ExchangeId.bybit || ExchangeId.bitget || ExchangeId.okx => false,
};

/// Order quantity that closes a position of [size], in the exchange's native
/// order unit, floored to [qtyStep].
///
/// Floors rather than rounds up: an over-sized reduce-only order is rejected
/// outright by some venues, while a floored one always places and leaves at
/// most one step of dust. Returns 0 when nothing placeable remains (below
/// [minQty], or a step larger than the position itself) — the caller reports
/// that as an unclosable remainder instead of sending a doomed order.
double closeOrderQty({
  required double size,
  required ExchangeId exchange,
  double? contractSize,
  double? qtyStep,
  double? minQty,
}) {
  final raw = size.abs();
  if (raw <= 0) return 0;
  if (!sizeNeedsContractConversion(exchange)) {
    return roundQty(raw, step: qtyStep, minQty: minQty);
  }
  final cs = contractSize ?? 1;
  if (cs <= 0) return 0;
  return roundQty(raw / cs, step: qtyStep, minQty: minQty);
}

/// Limit price that rests at the top of the book on the closing side, so the
/// order fills as a maker: closing a long sells at the best ask, closing a
/// short buys at the best bid.
///
/// Rounded *away* from the market (sell up, buy down) so a tick-rounded price
/// can never cross the spread and get the post-only order rejected. Falls back
/// to the mid when the book side is missing.
double makerLimitPrice({
  required Quote quote,
  required bool isLong,
  double? tickSize,
}) {
  if (isLong) {
    final raw = quote.ask > 0 ? quote.ask : quote.mid;
    return roundPriceUp(raw, tick: tickSize);
  }
  final raw = quote.bid > 0 ? quote.bid : quote.mid;
  return roundPriceDown(raw, tick: tickSize);
}

/// Limit price that crosses the book by [bufferPct] percent, used as the
/// last-resort taker fill: closing a long sells below the market, closing a
/// short buys above it. Rounded in the crossing direction so the buffer is
/// never rounded away.
double takerLimitPrice({
  required double refPrice,
  required bool isLong,
  required double bufferPct,
  double? tickSize,
}) {
  final factor = isLong ? 1 - bufferPct / 100 : 1 + bufferPct / 100;
  final raw = refPrice * factor;
  return isLong
      ? roundPriceDown(raw, tick: tickSize)
      : roundPriceUp(raw, tick: tickSize);
}

/// How many ticks the top of the book has moved away from a resting order at
/// [placedPrice]. Drives the decision to cancel and re-price: only movement
/// that leaves the order behind counts, so a market coming *to* the order
/// (which is about to fill it) reports 0.
double abandonedByTicks({
  required double placedPrice,
  required Quote quote,
  required bool isLong,
  double? tickSize,
}) {
  if (tickSize == null || tickSize <= 0) return 0;
  // A resting sell is left behind when the ask falls below it; a resting buy
  // when the bid rises above it.
  final best = isLong ? quote.ask : quote.bid;
  if (best <= 0) return 0;
  final behind = isLong ? placedPrice - best : best - placedPrice;
  return behind <= 0 ? 0 : behind / tickSize;
}
