import 'decimals.dart';

/// One sample of an instrument's raw spread for the live chart (§2.45 /
/// `/spread/history`). Money/ratio fields stay raw strings; parse with
/// [Decimals] for plotting.
class SpreadPoint {
  final int tsMs;

  /// Primary line: spread net of default fees, as a fraction.
  final String netPct;
  final String? baselinePct;
  final String? grossPct;

  /// Which venues form the best spread at this instant (can change).
  final String? buyExchange;
  final String? sellExchange;

  /// Entry quality: real depth available on both legs right now.
  final String? executableNotional;

  /// `true` = book can't supply full size → a thinner/mirage entry.
  final bool cappedByDepth;

  const SpreadPoint({
    required this.tsMs,
    required this.netPct,
    this.baselinePct,
    this.grossPct,
    this.buyExchange,
    this.sellExchange,
    this.executableNotional,
    this.cappedByDepth = false,
  });

  factory SpreadPoint.fromJson(Map<String, Object?> json) => SpreadPoint(
        tsMs: (json['ts_ms'] as num?)?.toInt() ?? 0,
        netPct: Decimals.str(json['net_pct']),
        baselinePct:
            json['baseline_pct'] == null ? null : Decimals.str(json['baseline_pct']),
        grossPct:
            json['gross_pct'] == null ? null : Decimals.str(json['gross_pct']),
        buyExchange: json['buy_exchange'] as String?,
        sellExchange: json['sell_exchange'] as String?,
        executableNotional: json['executable_notional'] == null
            ? null
            : Decimals.str(json['executable_notional']),
        cappedByDepth: json['capped_by_depth'] == true,
      );
}
