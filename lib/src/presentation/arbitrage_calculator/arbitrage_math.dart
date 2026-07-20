import 'dart:math' as math;

import 'package:crypto_position/src/market_data/market_data_provider.dart';

/// Inputs for one arbitrage-profitability estimate. Rates are per funding
/// interval as fractions (e.g. 0.0001); percents are whole-number percents
/// (e.g. 0.02 = 0.02%).
class ArbitrageInput {
  final double capital1;
  final double capital2;
  final double leverage;
  final double holdingHours;
  final double entrySpreadPct;
  final double exitSpreadPct;
  final double maker1Pct;
  final double maker2Pct;
  final double fundingRate1;
  final double fundingRate2;
  final double intervalHours1;
  final double intervalHours2;

  /// True when leg 1 is the long (cheaper) side. Drives which leg pays vs
  /// receives funding.
  final bool leg1IsLong;

  const ArbitrageInput({
    required this.capital1,
    required this.capital2,
    required this.leverage,
    required this.holdingHours,
    required this.entrySpreadPct,
    required this.exitSpreadPct,
    required this.maker1Pct,
    required this.maker2Pct,
    required this.fundingRate1,
    required this.fundingRate2,
    required this.intervalHours1,
    required this.intervalHours2,
    required this.leg1IsLong,
  });
}

class ArbitrageResult {
  /// Matched per-leg notional actually deployed (the smaller of the two legs).
  final double notional;

  /// Profit from the spread converging from entry to exit, in USD.
  final double grossUsd;

  /// Total maker fees across both legs, open + close, in USD (a cost).
  final double feesUsd;

  /// Net funding over the holding period, in USD (positive = income).
  final double fundingUsd;

  final double netUsd;

  /// Net profit as a percent of own capital deployed (both legs).
  final double netReturnPct;

  /// Annualized [netReturnPct].
  final double aprPct;

  const ArbitrageResult({
    required this.notional,
    required this.grossUsd,
    required this.feesUsd,
    required this.fundingUsd,
    required this.netUsd,
    required this.netReturnPct,
    required this.aprPct,
  });
}

/// Estimates round-trip arbitrage profit and its annualized return.
ArbitrageResult computeArbitrage(ArbitrageInput i) {
  // Market-neutral: both legs carry the same notional, capped by the smaller
  // funded leg. Surplus capital on the larger leg sits idle.
  final notional =
      (i.capital1 < i.capital2 ? i.capital1 : i.capital2) * i.leverage;

  final grossUsd = notional * (i.entrySpreadPct - i.exitSpreadPct) / 100;

  // Maker fee on each leg, applied on both the open and the close fill.
  final feesUsd = 2 * notional * (i.maker1Pct + i.maker2Pct) / 100;

  // A long pays funding (cost) when the rate is positive; a short receives it.
  final longRate = i.leg1IsLong ? i.fundingRate1 : i.fundingRate2;
  final shortRate = i.leg1IsLong ? i.fundingRate2 : i.fundingRate1;
  final longInterval = i.leg1IsLong ? i.intervalHours1 : i.intervalHours2;
  final shortInterval = i.leg1IsLong ? i.intervalHours2 : i.intervalHours1;
  final longPeriods = longInterval > 0 ? i.holdingHours / longInterval : 0;
  final shortPeriods = shortInterval > 0 ? i.holdingHours / shortInterval : 0;
  final fundingUsd =
      shortRate * notional * shortPeriods - longRate * notional * longPeriods;

  final netUsd = grossUsd + fundingUsd - feesUsd;

  final ownCapital = i.capital1 + i.capital2;
  final netReturnPct = ownCapital > 0 ? netUsd / ownCapital * 100 : 0.0;
  final aprPct =
      i.holdingHours > 0 ? netReturnPct * 8760 / i.holdingHours : 0.0;

  return ArbitrageResult(
    notional: notional,
    grossUsd: grossUsd,
    feesUsd: feesUsd,
    fundingUsd: fundingUsd,
    netUsd: netUsd,
    netReturnPct: netReturnPct,
    aprPct: aprPct,
  );
}

/// Result of walking an order book with a target size — how much of the
/// requested quantity the visible depth would absorb and at what average price.
class FillEstimate {
  /// Quantity requested, in base units.
  final double requestedQty;

  /// Quantity the visible book covers, in base units (<= [requestedQty]).
  final double filledQty;

  /// Volume-weighted average fill price over [filledQty], or 0 if nothing fills.
  final double avgPrice;

  /// Adverse slippage of [avgPrice] versus the reference (mid) price, in
  /// percent, always expressed as a cost (>= 0). 0 when nothing fills.
  final double slippagePct;

  /// True when the visible depth fully covers [requestedQty].
  final bool covered;

  const FillEstimate({
    required this.requestedQty,
    required this.filledQty,
    required this.avgPrice,
    required this.slippagePct,
    required this.covered,
  });
}

/// Simulates a market order of [qtyBase] base units against [book], crossing
/// asks when [isBuy] and bids otherwise. [referencePrice] (usually mid) anchors
/// the reported slippage. The book snapshot is an estimate, not a guarantee.
FillEstimate simulateFill({
  required OrderBook book,
  required double qtyBase,
  required bool isBuy,
  required double referencePrice,
}) {
  final levels = isBuy ? book.asks : book.bids;
  var remaining = qtyBase;
  var cost = 0.0; // sum(price * size) over filled portion
  var filled = 0.0;

  for (final level in levels) {
    if (remaining <= 0) break;
    final take = level.size < remaining ? level.size : remaining;
    cost += level.price * take;
    filled += take;
    remaining -= take;
  }

  final avgPrice = filled > 0 ? cost / filled : 0.0;
  var slippagePct = 0.0;
  if (filled > 0 && referencePrice > 0) {
    final raw = isBuy
        ? (avgPrice - referencePrice)
        : (referencePrice - avgPrice);
    slippagePct = raw / referencePrice * 100;
  }

  return FillEstimate(
    requestedQty: qtyBase,
    filledQty: filled,
    avgPrice: avgPrice,
    // Round-off can leave a hair of remaining size; treat within 0.01% as full.
    covered: remaining <= qtyBase * 1e-4,
    slippagePct: slippagePct,
  );
}

/// Floors [raw] down to a multiple of [step]. Returns 0 when the result would
/// fall below [minQty] (the order would be too small to place). [step]/[minQty]
/// null (exchange didn't report them) pass [raw] through unchanged.
double roundQty(double raw, {double? step, double? minQty}) {
  var q = raw;
  if (step != null && step > 0) {
    // Nudge before flooring so values like 0.3/0.1 don't drop a step to fp.
    q = ((raw / step) + 1e-9).floorToDouble() * step;
  }
  if (minQty != null && q < minQty) return 0;
  return q;
}

/// Rounds [raw] to the nearest multiple of [tick]. [tick] null passes [raw]
/// through unchanged.
double roundPrice(double raw, {double? tick}) {
  if (tick == null || tick <= 0) return raw;
  return (raw / tick).roundToDouble() * tick;
}

/// Converts a target notional ([capital] * [leverage]) at [price] into an order
/// size in the exchange's native unit (base units divided by [contractSize],
/// which is 1 where the exchange sizes orders in the base asset), floored to
/// [qtyStep] and dropped to 0 when below [minQty]. Returns 0 for a
/// non-positive [price] or [contractSize].
double nativeOrderQty({
  required double capital,
  required double leverage,
  required double price,
  double contractSize = 1,
  double? qtyStep,
  double? minQty,
}) {
  if (price <= 0 || contractSize <= 0) return 0;
  final baseQty = capital * leverage / price;
  return roundQty(baseQty / contractSize, step: qtyStep, minQty: minQty);
}

/// One historical spread point: the percent premium of leg 2 over leg 1 at
/// [tsMs].
class SpreadPoint {
  final int tsMs;
  final double spreadPct;

  const SpreadPoint(this.tsMs, this.spreadPct);
}

/// Aligns two candle series by timestamp and computes the spread of [leg2]
/// over [leg1] at each shared bucket, oldest first. Timestamps present on only
/// one exchange are dropped, so a venue that lists the coin later simply
/// shortens the history rather than skewing it.
List<SpreadPoint> spreadHistory(List<Candle> leg1, List<Candle> leg2) {
  final byTs2 = {for (final c in leg2) c.tsMs: c.close};
  final out = <SpreadPoint>[];
  for (final c1 in leg1) {
    final c2 = byTs2[c1.tsMs];
    if (c2 == null || c1.close <= 0) continue;
    out.add(SpreadPoint(c1.tsMs, (c2 - c1.close) / c1.close * 100));
  }
  out.sort((a, b) => a.tsMs.compareTo(b.tsMs));
  return out;
}

/// Rounds [raw] *up* to a multiple of [step] (null [step] passes through).
/// Used where a floor would breach an exchange minimum.
double roundQtyUp(double raw, {double? step}) {
  if (step == null || step <= 0) return raw;
  return ((raw / step) - 1e-9).ceilToDouble() * step;
}

/// Fallback minimum order value (USDT) for exchanges that don't report one.
/// Sized so a probe clears the common 5 USDT floor; the probe is cancelled
/// immediately, so erring large is harmless.
const kDefaultMinNotional = 6.0;

/// Price and size for the preflight canary probe: a limit order far from the
/// market ([isBuy] buys 50% below, sells 50% above) that must still clear the
/// exchange's minimum quantity *and* minimum order value. Because the probe
/// price is deliberately far from mid, sizing off [minQty] alone usually falls
/// short of the value floor — so the size is rounded **up** to whichever
/// minimum binds.
({double price, double qty}) canaryOrder({
  required double refPrice,
  required bool isBuy,
  double? tickSize,
  double? qtyStep,
  double? minQty,
  double? minNotional,
  double contractSize = 1,
}) {
  final price = roundPrice(refPrice * (isBuy ? 0.5 : 1.5), tick: tickSize);
  final cs = contractSize > 0 ? contractSize : 1.0;
  final notional = minNotional ?? kDefaultMinNotional;
  // Native units needed to reach the value floor at this (far) probe price.
  final qtyForNotional = price > 0 ? notional / (price * cs) : 0.0;
  final needed = math.max(minQty ?? 0, qtyForNotional);
  final qty = roundQtyUp(needed, step: qtyStep);
  return (price: price, qty: qty);
}

/// Limit prices for a spread entry. The long leg is anchored at its mid (a fair
/// price); the short leg is placed [entrySpreadPct] above the long price, so the
/// pair only fills once the spread reaches the target. Both are rounded to their
/// instrument tick. Prices share a scale (both legs are the same base asset).
({double longPrice, double shortPrice}) entryLimitPrices({
  required double longMid,
  required double entrySpreadPct,
  double? longTick,
  double? shortTick,
}) {
  final longPrice = roundPrice(longMid, tick: longTick);
  final shortPrice = roundPrice(
    longPrice * (1 + entrySpreadPct / 100),
    tick: shortTick,
  );
  return (longPrice: longPrice, shortPrice: shortPrice);
}
