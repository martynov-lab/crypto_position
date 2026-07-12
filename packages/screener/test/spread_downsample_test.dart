import 'package:flutter_test/flutter_test.dart';
import 'package:screener/screener.dart';

SpreadPoint p(int tsMs, String inPct, {bool capped = false}) => SpreadPoint(
      tsMs: tsMs,
      netPct: inPct,
      inPct: inPct,
      outPct: '-0.001',
      cappedByDepth: capped,
    );

void main() {
  group('downsampleSpread', () {
    test('raw (bucketMs <= 0) returns points unchanged', () {
      final points = [p(0, '0.01'), p(500, '0.02')];
      expect(downsampleSpread(points, 0), same(points));
    });

    test('keeps the last sample per bucket', () {
      final points = [
        p(0, '0.01'),
        p(20000, '0.02'),
        p(59000, '0.03'), // last in minute-0 bucket
        p(61000, '0.04'), // minute-1 bucket
        p(119000, '0.05'), // last in minute-1 bucket
      ];
      final out = downsampleSpread(points, 60000);
      expect(out.map((e) => e.inPct), ['0.03', '0.05']);
      expect(out.map((e) => e.tsMs), [59000, 119000]);
    });

    test('flags a bucket capped if any sample in it was capped', () {
      final points = [
        p(0, '0.01'),
        p(30000, '0.02', capped: true),
        p(59000, '0.03'), // last is not capped, but bucket had a mirage
      ];
      final out = downsampleSpread(points, 60000);
      expect(out.single.cappedByDepth, isTrue);
    });

    test('does not aggregate when fewer than 2 points', () {
      final points = [p(0, '0.01')];
      expect(downsampleSpread(points, 60000), same(points));
    });
  });
}
