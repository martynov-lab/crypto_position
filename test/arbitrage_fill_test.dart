import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('simulateFill', () {
    // Buy side crosses asks: 10 @ 100, 10 @ 101, 10 @ 102.
    const book = OrderBook(
      bids: [BookLevel(99, 10), BookLevel(98, 10)],
      asks: [BookLevel(100, 10), BookLevel(101, 10), BookLevel(102, 10)],
    );

    test('full fill within one level has no slippage vs that level', () {
      final f = simulateFill(
        book: book,
        qtyBase: 5,
        isBuy: true,
        referencePrice: 100,
      );
      expect(f.covered, isTrue);
      expect(f.filledQty, 5);
      expect(f.avgPrice, 100);
      expect(f.slippagePct, 0);
    });

    test('fill spanning levels reports weighted avg and slippage', () {
      // 10 @ 100 + 5 @ 101 => avg = (1000 + 505) / 15 = 100.333...
      final f = simulateFill(
        book: book,
        qtyBase: 15,
        isBuy: true,
        referencePrice: 100,
      );
      expect(f.covered, isTrue);
      expect(f.filledQty, 15);
      expect(f.avgPrice, closeTo(100.3333, 1e-3));
      expect(f.slippagePct, closeTo(0.3333, 1e-3));
    });

    test('depth shortfall marks partial coverage', () {
      final f = simulateFill(
        book: book,
        qtyBase: 40,
        isBuy: true,
        referencePrice: 100,
      );
      expect(f.covered, isFalse);
      expect(f.filledQty, 30); // only 30 available on the ask side
    });

    test('sell side crosses bids and slippage is a cost', () {
      // 10 @ 99 + 5 @ 98 => avg = (990 + 490) / 15 = 98.666...
      final f = simulateFill(
        book: book,
        qtyBase: 15,
        isBuy: false,
        referencePrice: 100,
      );
      expect(f.avgPrice, closeTo(98.6667, 1e-3));
      // Selling below mid is adverse, reported as a positive cost.
      expect(f.slippagePct, closeTo(1.3333, 1e-3));
    });

    test('empty book fills nothing', () {
      final f = simulateFill(
        book: const OrderBook(bids: [], asks: []),
        qtyBase: 5,
        isBuy: true,
        referencePrice: 100,
      );
      expect(f.covered, isFalse);
      expect(f.filledQty, 0);
      expect(f.avgPrice, 0);
      expect(f.slippagePct, 0);
    });
  });

  group('roundQty', () {
    test('floors to step', () {
      expect(roundQty(0.37, step: 0.1), closeTo(0.3, 1e-9));
    });

    test('exact multiples survive floating point', () {
      expect(roundQty(0.3, step: 0.1), closeTo(0.3, 1e-9));
    });

    test('below minQty returns 0', () {
      expect(roundQty(0.05, step: 0.01, minQty: 0.1), 0);
    });

    test('null step passes through', () {
      expect(roundQty(1.2345), 1.2345);
    });
  });

  group('roundPrice', () {
    test('rounds to nearest tick', () {
      expect(roundPrice(100.037, tick: 0.05), closeTo(100.05, 1e-9));
      expect(roundPrice(100.011, tick: 0.05), closeTo(100.0, 1e-9));
    });

    test('null tick passes through', () {
      expect(roundPrice(100.037), 100.037);
    });
  });

  group('nativeOrderQty', () {
    test('base-unit exchange: notional / price, floored to step', () {
      // 100 * 5 / 50 = 10 base units, step 0.001 => 10.
      expect(
        nativeOrderQty(capital: 100, leverage: 5, price: 50, qtyStep: 0.001),
        closeTo(10, 1e-9),
      );
    });

    test('contract exchange: divides by contract size', () {
      // 100 * 5 / 50 = 10 base; contractSize 0.01 => 1000 contracts, step 1.
      expect(
        nativeOrderQty(
          capital: 100,
          leverage: 5,
          price: 50,
          contractSize: 0.01,
          qtyStep: 1,
        ),
        closeTo(1000, 1e-9),
      );
    });

    test('returns 0 below minQty', () {
      expect(
        nativeOrderQty(
          capital: 1,
          leverage: 1,
          price: 50000,
          qtyStep: 0.001,
          minQty: 0.001,
        ),
        0,
      );
    });

    test('non-positive price yields 0', () {
      expect(nativeOrderQty(capital: 100, leverage: 5, price: 0), 0);
    });
  });

  group('entryLimitPrices', () {
    test('short leg sits entrySpread above the long, both tick-rounded', () {
      final p = entryLimitPrices(
        longMid: 100,
        entrySpreadPct: 1,
        longTick: 0.1,
        shortTick: 0.1,
      );
      expect(p.longPrice, closeTo(100, 1e-9));
      expect(p.shortPrice, closeTo(101, 1e-9));
    });

    test('zero spread places both legs at the same price', () {
      final p = entryLimitPrices(longMid: 250, entrySpreadPct: 0);
      expect(p.longPrice, 250);
      expect(p.shortPrice, 250);
    });
  });
}
