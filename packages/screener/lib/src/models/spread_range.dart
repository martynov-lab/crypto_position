import 'decimals.dart';
import 'signal_event.dart' show Instrument;

/// One coarse bucket of the long spread history (`GET /spread/range`, guide
/// §2.46): the best-pair net spread's min/max/close over the bucket
/// (default 1 minute).
class SpreadRangeBucket {
  final int tsMs;
  final String minNetPct;
  final String maxNetPct;
  final String closeNetPct;

  /// The pair at the bucket's *maximum* — not necessarily the pair active for
  /// the whole bucket.
  final String buyExchange;
  final String sellExchange;

  /// Samples folded into this bucket; below the expected count (60 for 1-min
  /// buckets at 1s sampling) means gaps — fewer than two live venues, or
  /// server downtime.
  final int samples;

  const SpreadRangeBucket({
    required this.tsMs,
    required this.minNetPct,
    required this.maxNetPct,
    required this.closeNetPct,
    required this.buyExchange,
    required this.sellExchange,
    required this.samples,
  });

  factory SpreadRangeBucket.fromJson(Map<String, Object?> json) =>
      SpreadRangeBucket(
        tsMs: (json['ts_ms'] as num?)?.toInt() ?? 0,
        minNetPct: Decimals.str(json['min_net_pct']),
        maxNetPct: Decimals.str(json['max_net_pct']),
        closeNetPct: Decimals.str(json['close_net_pct']),
        buyExchange: json['buy_exchange']?.toString() ?? '',
        sellExchange: json['sell_exchange']?.toString() ?? '',
        samples: (json['samples'] as num?)?.toInt() ?? 0,
      );
}

/// `GET /spread/range` response: per-minute min/max/close of the best net
/// spread over up to several days — answers "how wide does this coin's
/// spread even get". In-memory on the server only: accumulates from server
/// start and is lost on restart; per-venue detail is not retained (only the
/// fine, ~30 min window from `/spread/history` has that).
class SpreadRange {
  final Instrument instrument;
  final int resolutionMs;
  final int windowMs;
  final List<SpreadRangeBucket> buckets;

  const SpreadRange({
    required this.instrument,
    required this.resolutionMs,
    required this.windowMs,
    required this.buckets,
  });

  factory SpreadRange.fromJson(Map<String, Object?> json) {
    final rows = (json['buckets'] as List?) ?? const [];
    return SpreadRange(
      instrument: Instrument.fromJson(
        (json['instrument'] as Map).cast<String, Object?>(),
      ),
      resolutionMs: (json['resolution_ms'] as num?)?.toInt() ?? 0,
      windowMs: (json['window_ms'] as num?)?.toInt() ?? 0,
      buckets: rows
          .whereType<Map>()
          .map((e) => SpreadRangeBucket.fromJson(e.cast<String, Object?>()))
          .toList(),
    );
  }
}
