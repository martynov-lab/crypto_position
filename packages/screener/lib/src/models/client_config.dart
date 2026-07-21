/// Documented server-side defaults for [ClientConfig] (integration guide §3).
///
/// Used to seed the filters UI so the user sees the effective values before
/// changing anything. `taker_fee` is per-venue and intentionally not surfaced.
class ScreenerDefaults {
  const ScreenerDefaults._();

  static const quote = 'USDT';
  static const minNetSpreadPct = '0.006';
  static const maxNetSpreadPct = '0.25';
  static const minRoundTripPct = '0.001';
  static const min24hQuoteVolume = '100000';
  static const max24hQuoteVolume = '200000';
  static const marketPairs = [MarketPair.perpPerp];
  static const targetNotionalQ = '2000';
  static const minExecutableNotional = '500';
  static const depthLevelsN = 20;
  static const includeFundingDiff = true;
  static const minFundingDiffApr = '0.15';
  static const fundingHoldHours = '8';
  static const includeFundingCost = true;
  static const maxBookAgeMs = 3000;
  static const maxLegSkewMs = 750;
  static const maxPriceDeviationPct = '0.10';
  static const episodeCloseTicks = 3;
  static const enableDynamics = true;
  static const maxBaselineSpreadPct = '0.01';
  static const minSpikeZ = '3';
  static const maxSpreadDurationMs = 300000;
  static const minDynamicsSamples = 20;
  static const maxChartSpreadPct = '0.50';
  static const hysteresisStepPct = '0.005';
  static const minSignalLifetimeMs = 1500;
  static const cooldownMs = 2000;
  static const maxSignalsPerMin = 120;
  static const requireTransferable = false;
  static const requireCommonNetwork = false;

  static const allExchanges = <String>[
    'bybit',
    'okx',
    'mexc',
    'bitget',
    'gate',
    'coinex',
    'kucoin',
    'phemex',
  ];
}

/// One market-kind combination to screen: the market of the buy (long) leg vs
/// the sell (short) leg. Only `perp`/`perp` is live server-side today; spot
/// legs are accepted for forward compatibility.
class MarketPair {
  final String buy;
  final String sell;

  const MarketPair({required this.buy, required this.sell});

  static const perpPerp = MarketPair(buy: 'perp', sell: 'perp');

  Map<String, String> toJson() => {'buy': buy, 'sell': sell};

  @override
  bool operator ==(Object other) =>
      other is MarketPair && other.buy == buy && other.sell == sell;

  @override
  int get hashCode => Object.hash(buy, sell);
}

/// The subscribe-time filter set. Every field is optional; a `null` field is
/// omitted from the wire message so the server applies its own default.
///
/// Decimal fields are kept as strings end-to-end (never `double`) per the
/// wire-format rules.
class ClientConfig {
  final List<String>? exchanges;
  final String? quote;
  final List<String>? allowSymbols;
  final List<String>? denySymbols;
  final List<MarketPair>? marketPairs;
  final String? min24hQuoteVolume;

  /// 24h volume ceiling. `null` omits the field (server default applies);
  /// [maxVolumeOff] sends an explicit JSON `null` — ceiling disabled.
  final String? max24hQuoteVolume;
  final String? minOpenInterest;

  /// Sentinel for [max24hQuoteVolume]: an empty string encodes the wire's
  /// explicit `"max_24h_quote_volume": null`.
  static const maxVolumeOff = '';
  final String? minNetSpreadPct;
  final String? maxNetSpreadPct;

  /// The real profitability gate: floor on `round_trip_pct` (entry minus the
  /// unwind level, four taker fees and the funding carry).
  final String? minRoundTripPct;
  final String? targetNotionalQ;
  final String? minExecutableNotional;
  final int? depthLevelsN;
  final bool? includeFundingDiff;
  final String? minFundingDiffApr;
  final String? fundingHoldHours;

  /// Subtract the pair's funding carry from `round_trip_pct`.
  final bool? includeFundingCost;
  final bool? requireTransferable;
  final bool? requireCommonNetwork;
  final int? maxBookAgeMs;

  /// Max age gap between the two legs' books; `0` = off.
  final int? maxLegSkewMs;

  /// Drop a venue whose mid is this far from the cross-venue median (needs ≥3
  /// venues). Left unset the server default applies.
  final String? maxPriceDeviationPct;
  final bool? enableDynamics;
  final String? maxBaselineSpreadPct;
  final String? minSpikeZ;
  final int? maxSpreadDurationMs;
  final int? minDynamicsSamples;
  final String? maxChartSpreadPct;
  final String? hysteresisStepPct;

  /// Consecutive rejects before an episode closes and hysteresis re-arms.
  final int? episodeCloseTicks;
  final int? minSignalLifetimeMs;
  final int? cooldownMs;
  final int? maxSignalsPerMin;

  const ClientConfig({
    this.exchanges,
    this.quote,
    this.allowSymbols,
    this.denySymbols,
    this.marketPairs,
    this.min24hQuoteVolume,
    this.max24hQuoteVolume,
    this.minOpenInterest,
    this.minNetSpreadPct,
    this.maxNetSpreadPct,
    this.minRoundTripPct,
    this.targetNotionalQ,
    this.minExecutableNotional,
    this.depthLevelsN,
    this.includeFundingDiff,
    this.minFundingDiffApr,
    this.fundingHoldHours,
    this.includeFundingCost,
    this.requireTransferable,
    this.requireCommonNetwork,
    this.maxBookAgeMs,
    this.maxLegSkewMs,
    this.maxPriceDeviationPct,
    this.enableDynamics,
    this.maxBaselineSpreadPct,
    this.minSpikeZ,
    this.maxSpreadDurationMs,
    this.minDynamicsSamples,
    this.maxChartSpreadPct,
    this.hysteresisStepPct,
    this.episodeCloseTicks,
    this.minSignalLifetimeMs,
    this.cooldownMs,
    this.maxSignalsPerMin,
  });

  /// Wire JSON with `null` fields dropped, so unset knobs fall back to the
  /// server defaults (including per-venue `taker_fee`).
  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    void put(String key, Object? value) {
      if (value != null) json[key] = value;
    }

    put('exchanges', exchanges);
    put('quote', quote);
    put('allow_symbols', allowSymbols);
    put('deny_symbols', denySymbols);
    put('market_pairs',
        marketPairs?.map((pair) => pair.toJson()).toList());
    put('min_24h_quote_volume', min24hQuoteVolume);
    if (max24hQuoteVolume == maxVolumeOff) {
      json['max_24h_quote_volume'] = null;
    } else {
      put('max_24h_quote_volume', max24hQuoteVolume);
    }
    put('min_open_interest', minOpenInterest);
    put('min_net_spread_pct', minNetSpreadPct);
    put('max_net_spread_pct', maxNetSpreadPct);
    put('min_round_trip_pct', minRoundTripPct);
    put('target_notional_q', targetNotionalQ);
    put('min_executable_notional', minExecutableNotional);
    put('depth_levels_n', depthLevelsN);
    put('include_funding_diff', includeFundingDiff);
    put('min_funding_diff_apr', minFundingDiffApr);
    put('funding_hold_hours', fundingHoldHours);
    put('include_funding_cost', includeFundingCost);
    put('require_transferable', requireTransferable);
    put('require_common_network', requireCommonNetwork);
    put('max_book_age_ms', maxBookAgeMs);
    put('max_leg_skew_ms', maxLegSkewMs);
    put('max_price_deviation_pct', maxPriceDeviationPct);
    put('enable_dynamics', enableDynamics);
    put('max_baseline_spread_pct', maxBaselineSpreadPct);
    put('min_spike_z', minSpikeZ);
    put('max_spread_duration_ms', maxSpreadDurationMs);
    put('min_dynamics_samples', minDynamicsSamples);
    put('max_chart_spread_pct', maxChartSpreadPct);
    put('hysteresis_step_pct', hysteresisStepPct);
    put('episode_close_ticks', episodeCloseTicks);
    put('min_signal_lifetime_ms', minSignalLifetimeMs);
    put('cooldown_ms', cooldownMs);
    put('max_signals_per_min', maxSignalsPerMin);
    return json;
  }
}
