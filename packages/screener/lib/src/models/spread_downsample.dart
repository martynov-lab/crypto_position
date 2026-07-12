import 'spread_point.dart';

/// Aggregates raw [points] into one point per [bucketMs] window (the chart's
/// timeframe). Each bucket keeps the **last** sample's values (its "close") and
/// is flagged `capped_by_depth` if *any* sample in the window was capped, so a
/// mirage inside the interval stays visible.
///
/// `bucketMs <= 0` (raw) returns [points] unchanged. Decimal-safe: it only
/// selects existing string values, never averages floats.
List<SpreadPoint> downsampleSpread(List<SpreadPoint> points, int bucketMs) {
  if (bucketMs <= 0 || points.length < 2) return points;

  final byBucket = <int, List<SpreadPoint>>{};
  for (final point in points) {
    byBucket.putIfAbsent(point.tsMs ~/ bucketMs, () => []).add(point);
  }

  final keys = byBucket.keys.toList()..sort();
  return [
    for (final key in keys)
      _reduce(byBucket[key]!),
  ];
}

SpreadPoint _reduce(List<SpreadPoint> bucket) {
  final last = bucket.last;
  final anyCapped = bucket.any((p) => p.cappedByDepth);
  return SpreadPoint(
    tsMs: last.tsMs,
    netPct: last.netPct,
    inPct: last.inPct,
    outPct: last.outPct,
    baselinePct: last.baselinePct,
    grossPct: last.grossPct,
    buyExchange: last.buyExchange,
    sellExchange: last.sellExchange,
    executableNotional: last.executableNotional,
    cappedByDepth: anyCapped,
    fundingLongPct: last.fundingLongPct,
    fundingShortPct: last.fundingShortPct,
  );
}
