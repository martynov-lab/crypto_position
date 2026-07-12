import 'decimals.dart';

/// One sample of an instrument's raw spread for the live chart (§2.45 /
/// `/spread/history`). Money/ratio fields stay raw strings; parse with
/// [Decimals] for plotting.
class SpreadPoint {
  final int tsMs;

  /// Legacy single-line value (= [inPct] for the fixed pair), net of fees.
  final String netPct;

  /// Entry spread (open the position now) net of fees — the green line. `null`
  /// on an old single-line server; fall back to [netPct].
  final String? inPct;

  /// Exit spread (close now) net of fees, usually ≤ 0 — the red line. Reverts
  /// toward 0 as the pair converges.
  final String? outPct;
  final String? baselinePct;
  final String? grossPct;

  /// The fixed pair's venues (constant across the watch).
  final String? buyExchange;
  final String? sellExchange;

  /// Entry quality: real depth available on both legs right now.
  final String? executableNotional;

  /// `true` = book can't supply full size → a thinner/mirage entry.
  final bool cappedByDepth;

  /// Per-leg funding rate at [tsMs] (fraction per interval).
  final String? fundingLongPct;
  final String? fundingShortPct;

  const SpreadPoint({
    required this.tsMs,
    required this.netPct,
    this.inPct,
    this.outPct,
    this.baselinePct,
    this.grossPct,
    this.buyExchange,
    this.sellExchange,
    this.executableNotional,
    this.cappedByDepth = false,
    this.fundingLongPct,
    this.fundingShortPct,
  });

  /// Entry-line value, preferring [inPct] and falling back to the legacy
  /// [netPct].
  String get entryPct => inPct ?? netPct;

  static String? _optStr(Object? value) =>
      value == null ? null : Decimals.str(value);

  factory SpreadPoint.fromJson(Map<String, Object?> json) => SpreadPoint(
        tsMs: (json['ts_ms'] as num?)?.toInt() ?? 0,
        netPct: Decimals.str(json['net_pct']),
        inPct: _optStr(json['in_pct']),
        outPct: _optStr(json['out_pct']),
        baselinePct: _optStr(json['baseline_pct']),
        grossPct: _optStr(json['gross_pct']),
        buyExchange: json['buy_exchange'] as String?,
        sellExchange: json['sell_exchange'] as String?,
        executableNotional: _optStr(json['executable_notional']),
        cappedByDepth: json['capped_by_depth'] == true,
        fundingLongPct: _optStr(json['funding_long_pct']),
        fundingShortPct: _optStr(json['funding_short_pct']),
      );
}
