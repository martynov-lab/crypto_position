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

    test('keeps the last sample per closed bucket', () {
      final points = [
        p(0, '0.01'),
        p(20000, '0.02'),
        p(59000, '0.03'), // last in minute-0 bucket
        p(61000, '0.04'), // minute-1 bucket
        p(119000, '0.05'), // last in minute-1 bucket
        p(121000, '0.06'), // minute-2 bucket, still open
      ];
      final out = downsampleSpread(points, 60000);
      expect(out.map((e) => e.inPct), ['0.03', '0.05', '0.06']);
      expect(out.map((e) => e.tsMs), [59000, 119000, 121000]);
    });

    test('leaves the open (newest) bucket as raw ticks', () {
      final points = [
        p(0, '0.01'),
        p(59000, '0.02'), // closes the minute-0 bucket
        p(61000, '0.03'),
        p(62000, '0.04'),
        p(63000, '0.05'),
      ];
      final out = downsampleSpread(points, 60000);
      expect(out.map((e) => e.inPct), ['0.02', '0.03', '0.04', '0.05']);
    });

    test('flags a closed bucket capped if any sample in it was capped', () {
      final points = [
        p(0, '0.01'),
        p(30000, '0.02', capped: true),
        p(59000, '0.03'), // last is not capped, but bucket had a mirage
        p(61000, '0.04'), // opens the next bucket, so minute 0 is closed
      ];
      final out = downsampleSpread(points, 60000);
      expect(out.first.cappedByDepth, isTrue);
    });

    test('does not aggregate when fewer than 2 points', () {
      final points = [p(0, '0.01')];
      expect(downsampleSpread(points, 60000), same(points));
    });
  });
}
