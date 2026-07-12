import 'decimals.dart';

/// Header metadata from a `watch_snapshot`: the pinned pair + funding labels for
/// the chart title, legend and countdown.
class WatchMeta {
  final String? longExchange;
  final String? shortExchange;
  final int resolutionMs;
  final int windowMs;

  /// Funding period in hours (e.g. `"1"`, `"8"`), for the "next in mm:ss".
  final String? fundingIntervalHours;

  /// Epoch ms of the soonest of the two legs' next funding settlement.
  final int? nextFundingMs;

  /// Current annualized funding per leg, for the right-edge labels.
  final String? fundingLongApr;
  final String? fundingShortApr;

  const WatchMeta({
    this.longExchange,
    this.shortExchange,
    this.resolutionMs = 0,
    this.windowMs = 0,
    this.fundingIntervalHours,
    this.nextFundingMs,
    this.fundingLongApr,
    this.fundingShortApr,
  });

  factory WatchMeta.fromJson(Map<String, Object?> json) => WatchMeta(
        longExchange: json['long_exchange'] as String?,
        shortExchange: json['short_exchange'] as String?,
        resolutionMs: (json['resolution_ms'] as num?)?.toInt() ?? 0,
        windowMs: (json['window_ms'] as num?)?.toInt() ?? 0,
        fundingIntervalHours: json['funding_interval_hours'] == null
            ? null
            : Decimals.str(json['funding_interval_hours']),
        nextFundingMs: (json['next_funding_ms'] as num?)?.toInt(),
        fundingLongApr: json['funding_long_apr'] == null
            ? null
            : Decimals.str(json['funding_long_apr']),
        fundingShortApr: json['funding_short_apr'] == null
            ? null
            : Decimals.str(json['funding_short_apr']),
      );
}
