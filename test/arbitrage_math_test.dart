import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeArbitrage', () {
    test('spread profit net of fees, no funding', () {
      final r = computeArbitrage(
        const ArbitrageInput(
          capital1: 1000,
          capital2: 1000,
          leverage: 5,
          holdingHours: 8,
          entrySpreadPct: 1.0,
          exitSpreadPct: 0.0,
          maker1Pct: 0.02,
          maker2Pct: 0.02,
          fundingRate1: 0,
          fundingRate2: 0,
          intervalHours1: 8,
          intervalHours2: 8,
          leg1IsLong: true,
        ),
      );

      // notional = min(1000,1000)*5 = 5000
      expect(r.notional, 5000);
      // gross = 5000 * 1% = 50
      expect(r.grossUsd, closeTo(50, 1e-9));
      // fees = 2 * 5000 * (0.02+0.02)% = 2*5000*0.0004 = 4
      expect(r.feesUsd, closeTo(4, 1e-9));
      expect(r.fundingUsd, 0);
      expect(r.netUsd, closeTo(46, 1e-9));
      // return on own capital = 46 / 2000 = 2.3%
      expect(r.netReturnPct, closeTo(2.3, 1e-9));
      // APR = 2.3% * 8760/8 = 2518.5%
      expect(r.aprPct, closeTo(2.3 * 8760 / 8, 1e-6));
    });

    test('funding: short leg receives, long leg pays', () {
      final r = computeArbitrage(
        const ArbitrageInput(
          capital1: 1000,
          capital2: 1000,
          leverage: 1,
          holdingHours: 8,
          entrySpreadPct: 0,
          exitSpreadPct: 0,
          maker1Pct: 0,
          maker2Pct: 0,
          // leg1 long pays 0.01%; leg2 short receives 0.02%.
          fundingRate1: 0.0001,
          fundingRate2: 0.0002,
          intervalHours1: 8,
          intervalHours2: 8,
          leg1IsLong: true,
        ),
      );

      // notional = 1000. One interval each.
      // funding = short(0.0002)*1000 - long(0.0001)*1000 = 0.2 - 0.1 = 0.1
      expect(r.fundingUsd, closeTo(0.1, 1e-9));
      expect(r.netUsd, closeTo(0.1, 1e-9));
    });

    test('uses the smaller funded leg as the matched notional', () {
      final r = computeArbitrage(
        const ArbitrageInput(
          capital1: 500,
          capital2: 2000,
          leverage: 10,
          holdingHours: 24,
          entrySpreadPct: 0,
          exitSpreadPct: 0,
          maker1Pct: 0,
          maker2Pct: 0,
          fundingRate1: 0,
          fundingRate2: 0,
          intervalHours1: 8,
          intervalHours2: 8,
          leg1IsLong: true,
        ),
      );

      // notional = min(500,2000)*10 = 5000
      expect(r.notional, 5000);
    });
  });

  group('executableSpreadPct', () {
    test('buys the ask and sells the bid, quoted off the buy price', () {
      final pct = executableSpreadPct(
        buy: const Quote(bid: 99, ask: 100, last: 99.5),
        sell: const Quote(bid: 101, ask: 102, last: 101.5),
      );

      // (101 - 100) / 100 = 1%. Mid-to-mid would have read 1.5% — the half
      // book spread on each leg that the trade never actually gets.
      expect(pct, closeTo(1.0, 1e-9));
    });

    test('falls back to mid when a book side is missing', () {
      final pct = executableSpreadPct(
        buy: const Quote(bid: 0, ask: 0, last: 100),
        sell: const Quote(bid: 101, ask: 102, last: 101.5),
      );

      expect(pct, closeTo(1.0, 1e-9));
    });

    test('goes negative once the pair has inverted', () {
      final pct = executableSpreadPct(
        buy: const Quote(bid: 101, ask: 102, last: 101.5),
        sell: const Quote(bid: 99, ask: 100, last: 99.5),
      );

      expect(pct, lessThan(0));
    });

    test('is null without a usable buy price', () {
      final pct = executableSpreadPct(
        buy: const Quote(bid: 0, ask: 0, last: 0),
        sell: const Quote(bid: 101, ask: 102, last: 101.5),
      );

      expect(pct, isNull);
    });
  });
}
