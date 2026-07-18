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
