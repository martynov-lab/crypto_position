import 'decimals.dart';

/// One row of the traded-instrument catalog: which venues list a `base/quote`
/// perp. Delivered in the `universe` WS push and via `GET /instruments`.
class InstrumentCoverage {
  final String base;
  final String quote;
  final List<String> exchanges;
  final int coverage;

  const InstrumentCoverage({
    required this.base,
    required this.quote,
    required this.exchanges,
    required this.coverage,
  });

  String get pair => '$base/$quote';

  factory InstrumentCoverage.fromJson(Map<String, Object?> json) {
    final exchanges = (json['exchanges'] as List?)
            ?.map((e) => Decimals.str(e))
            .toList() ??
        const <String>[];
    return InstrumentCoverage(
      base: Decimals.str(json['base']),
      quote: Decimals.str(json['quote']),
      exchanges: exchanges,
      coverage: (json['coverage'] as num?)?.toInt() ?? exchanges.length,
    );
  }
}
