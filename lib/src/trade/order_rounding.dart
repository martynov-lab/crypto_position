// Rounding of order quantities and prices to the increments an exchange
// accepts. Shared by the arbitrage entry math and the position-close math, so
// both round identically — a mismatch here is rejected orders or dust left on
// a position.

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

/// Rounds [raw] *up* to a multiple of [step] (null [step] passes through).
/// Used where a floor would breach an exchange minimum.
double roundQtyUp(double raw, {double? step}) {
  if (step == null || step <= 0) return raw;
  return ((raw / step) - 1e-9).ceilToDouble() * step;
}

/// Rounds [raw] to the nearest multiple of [tick]. [tick] null passes [raw]
/// through unchanged.
double roundPrice(double raw, {double? tick}) {
  if (tick == null || tick <= 0) return raw;
  return (raw / tick).roundToDouble() * tick;
}

/// Rounds [raw] *down* to a multiple of [tick]. Used where rounding to the
/// nearest tick could push a price the wrong way — a post-only sell must never
/// land below the best ask, a crossing sell must not land above its target.
double roundPriceDown(double raw, {double? tick}) {
  if (tick == null || tick <= 0) return raw;
  return ((raw / tick) + 1e-9).floorToDouble() * tick;
}

/// Rounds [raw] *up* to a multiple of [tick]. The mirror of [roundPriceDown]
/// for the buy side.
double roundPriceUp(double raw, {double? tick}) {
  if (tick == null || tick <= 0) return raw;
  return ((raw / tick) - 1e-9).ceilToDouble() * tick;
}
