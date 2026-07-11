/// Documented server-side defaults for [ClientConfig] (integration guide §3).
///
/// Used to seed the filters UI so the user sees the effective values before
/// changing anything. `taker_fee` is per-venue and intentionally not surfaced.
class ScreenerDefaults {
  const ScreenerDefaults._();

  static const quote = 'USDT';
  static const minNetSpreadPct = '0.02';
  static const maxNetSpreadPct = '0.20';
  static const targetNotionalQ = '2000';
  static const minExecutableNotional = '500';
  static const depthLevelsN = 20;
  static const includeFundingDiff = true;
  static const minFundingDiffApr = '0.15';
  static const fundingHoldHours = '8';
  static const maxBookAgeMs = 3000;
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
  final String? min24hQuoteVolume;
  final String? minOpenInterest;
  final String? minNetSpreadPct;
  final String? maxNetSpreadPct;
  final String? targetNotionalQ;
  final String? minExecutableNotional;
  final int? depthLevelsN;
  final bool? includeFundingDiff;
  final String? minFundingDiffApr;
  final String? fundingHoldHours;
  final bool? requireTransferable;
  final bool? requireCommonNetwork;
  final int? maxBookAgeMs;
  final bool? enableDynamics;
  final String? maxBaselineSpreadPct;
  final String? minSpikeZ;
  final int? maxSpreadDurationMs;
  final int? minDynamicsSamples;
  final String? maxChartSpreadPct;
  final String? hysteresisStepPct;
  final int? minSignalLifetimeMs;
  final int? cooldownMs;
  final int? maxSignalsPerMin;

  const ClientConfig({
    this.exchanges,
    this.quote,
    this.allowSymbols,
    this.denySymbols,
    this.min24hQuoteVolume,
    this.minOpenInterest,
    this.minNetSpreadPct,
    this.maxNetSpreadPct,
    this.targetNotionalQ,
    this.minExecutableNotional,
    this.depthLevelsN,
    this.includeFundingDiff,
    this.minFundingDiffApr,
    this.fundingHoldHours,
    this.requireTransferable,
    this.requireCommonNetwork,
    this.maxBookAgeMs,
    this.enableDynamics,
    this.maxBaselineSpreadPct,
    this.minSpikeZ,
    this.maxSpreadDurationMs,
    this.minDynamicsSamples,
    this.maxChartSpreadPct,
    this.hysteresisStepPct,
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
    put('min_24h_quote_volume', min24hQuoteVolume);
    put('min_open_interest', minOpenInterest);
    put('min_net_spread_pct', minNetSpreadPct);
    put('max_net_spread_pct', maxNetSpreadPct);
    put('target_notional_q', targetNotionalQ);
    put('min_executable_notional', minExecutableNotional);
    put('depth_levels_n', depthLevelsN);
    put('include_funding_diff', includeFundingDiff);
    put('min_funding_diff_apr', minFundingDiffApr);
    put('funding_hold_hours', fundingHoldHours);
    put('require_transferable', requireTransferable);
    put('require_common_network', requireCommonNetwork);
    put('max_book_age_ms', maxBookAgeMs);
    put('enable_dynamics', enableDynamics);
    put('max_baseline_spread_pct', maxBaselineSpreadPct);
    put('min_spike_z', minSpikeZ);
    put('max_spread_duration_ms', maxSpreadDurationMs);
    put('min_dynamics_samples', minDynamicsSamples);
    put('max_chart_spread_pct', maxChartSpreadPct);
    put('hysteresis_step_pct', hysteresisStepPct);
    put('min_signal_lifetime_ms', minSignalLifetimeMs);
    put('cooldown_ms', cooldownMs);
    put('max_signals_per_min', maxSignalsPerMin);
    return json;
  }
}
