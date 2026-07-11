import 'decimals.dart';

/// One row of `GET /summary`: the current best spread per instrument, highest
/// net spread first. Useful for a cold-start snapshot before the first WS
/// `event` arrives.
class SummaryEntry {
  /// Already in `BASE/QUOTE` form from the server.
  final String instrument;
  final String buyExchange;
  final String sellExchange;
  final String netPct;

  /// Number of venues with a usable book.
  final int coverage;

  const SummaryEntry({
    required this.instrument,
    required this.buyExchange,
    required this.sellExchange,
    required this.netPct,
    required this.coverage,
  });

  factory SummaryEntry.fromJson(Map<String, Object?> json) => SummaryEntry(
        instrument: Decimals.str(json['instrument']),
        buyExchange: Decimals.str(json['buy_exchange']),
        sellExchange: Decimals.str(json['sell_exchange']),
        netPct: Decimals.str(json['net_pct']),
        coverage: (json['coverage'] as num?)?.toInt() ?? 0,
      );
}
