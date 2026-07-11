import 'package:decimal/decimal.dart';

import 'decimals.dart';

/// A traded instrument: `base/quote` on a market `kind` (only `perp` in
/// Phase 1).
class Instrument {
  final String base;
  final String quote;
  final String kind;

  const Instrument({
    required this.base,
    required this.quote,
    required this.kind,
  });

  /// `BTC/USDT` — stable key for the newest-wins live table.
  String get pair => '$base/$quote';

  factory Instrument.fromJson(Map<String, Object?> json) => Instrument(
        base: Decimals.str(json['base']),
        quote: Decimals.str(json['quote']),
        kind: Decimals.str(json['kind']),
      );
}

/// The executable spread: where to buy (lowest ask) vs sell (highest bid), the
/// VWAP prices, and the fee-net edge. All ratio/price fields are raw strings.
class Spread {
  final Instrument instrument;
  final String buyExchange;
  final String sellExchange;
  final String vwapBuy;
  final String vwapSell;
  final String grossPct;

  /// Already net of taker fees on both legs.
  final String netPct;
  final String executableNotional;

  /// `true` when the book could not supply the full `target_notional_q` — a
  /// thinner, riskier opportunity.
  final bool cappedByDepth;

  const Spread({
    required this.instrument,
    required this.buyExchange,
    required this.sellExchange,
    required this.vwapBuy,
    required this.vwapSell,
    required this.grossPct,
    required this.netPct,
    required this.executableNotional,
    required this.cappedByDepth,
  });

  Decimal? get netPctValue => Decimals.parse(netPct);

  factory Spread.fromJson(Map<String, Object?> json) => Spread(
        instrument: Instrument.fromJson(
          (json['instrument'] as Map).cast<String, Object?>(),
        ),
        buyExchange: Decimals.str(json['buy_exchange']),
        sellExchange: Decimals.str(json['sell_exchange']),
        vwapBuy: Decimals.str(json['vwap_buy']),
        vwapSell: Decimals.str(json['vwap_sell']),
        grossPct: Decimals.str(json['gross_pct']),
        netPct: Decimals.str(json['net_pct']),
        executableNotional: Decimals.str(json['executable_notional']),
        cappedByDepth: json['capped_by_depth'] == true,
      );
}

/// Funding differential leg (omitted by the server when unavailable).
class Funding {
  final String longExchange;
  final String shortExchange;
  final String diffApr;

  const Funding({
    required this.longExchange,
    required this.shortExchange,
    required this.diffApr,
  });

  factory Funding.fromJson(Map<String, Object?> json) => Funding(
        longExchange: Decimals.str(json['long_exchange']),
        shortExchange: Decimals.str(json['short_exchange']),
        diffApr: Decimals.str(json['diff_apr']),
      );
}

/// Spread dynamics — the "real vs mirage" signal (omitted when unavailable).
class SpreadDynamics {
  /// Median spread over the rolling window; a *tight* baseline with a large
  /// [currentPct] is the healthy, capturable pattern.
  final String baselinePct;
  final String stddevPct;
  final String currentPct;

  /// Stddevs the current spread sits above its own mean; a high z is a genuine
  /// spike, not "it's always wide".
  final String zScore;
  final int sampleCount;

  /// How long the spread has stayed above the reference threshold; a large
  /// value means it is not reverting (likely a structural trap).
  final int episodeMs;

  const SpreadDynamics({
    required this.baselinePct,
    required this.stddevPct,
    required this.currentPct,
    required this.zScore,
    required this.sampleCount,
    required this.episodeMs,
  });

  factory SpreadDynamics.fromJson(Map<String, Object?> json) => SpreadDynamics(
        baselinePct: Decimals.str(json['baseline_pct']),
        stddevPct: Decimals.str(json['stddev_pct']),
        currentPct: Decimals.str(json['current_pct']),
        zScore: Decimals.str(json['z_score']),
        sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
        episodeMs: (json['episode_ms'] as num?)?.toInt() ?? 0,
      );
}

/// A fresh, filter-passing, non-duplicate arbitrage signal.
///
/// [funding], [dynamics] and [qualityScore] are omitted by the server when
/// unavailable.
class SignalEvent {
  final Spread spread;
  final Funding? funding;
  final SpreadDynamics? dynamics;

  /// 0–100 composite (tight baseline + strong spike + short episode + broad
  /// coverage). Sort/alert by this to surface the best coins.
  final String? qualityScore;
  final int tsMs;

  const SignalEvent({
    required this.spread,
    required this.tsMs,
    this.funding,
    this.dynamics,
    this.qualityScore,
  });

  Instrument get instrument => spread.instrument;

  /// Sort key for the live table: higher quality first, falling back to the
  /// net edge when the score is absent.
  Decimal get sortScore =>
      Decimals.parse(qualityScore) ??
      spread.netPctValue ??
      Decimal.zero;

  factory SignalEvent.fromJson(Map<String, Object?> json) {
    final funding = json['funding'];
    final dynamics = json['dynamics'];
    final quality = json['quality_score'];
    return SignalEvent(
      spread: Spread.fromJson((json['spread'] as Map).cast<String, Object?>()),
      funding: funding is Map
          ? Funding.fromJson(funding.cast<String, Object?>())
          : null,
      dynamics: dynamics is Map
          ? SpreadDynamics.fromJson(dynamics.cast<String, Object?>())
          : null,
      qualityScore: quality == null ? null : Decimals.str(quality),
      tsMs: (json['ts_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
