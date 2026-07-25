import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/trade/position_close_math.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('positionIsLong', () {
    test('reads every wording the exchanges use', () {
      expect(positionIsLong('Buy'), isTrue);
      expect(positionIsLong('long'), isTrue);
      expect(positionIsLong('Sell'), isFalse);
      expect(positionIsLong('short'), isFalse);
    });

    test('returns null on an unknown wording rather than guessing', () {
      expect(positionIsLong('net'), isNull);
      expect(positionIsLong(''), isNull);
    });
  });

  group('closeOrderSide', () {
    test('sells to close a long, buys to close a short', () {
      expect(closeOrderSide(isLong: true), OrderSide.sell);
      expect(closeOrderSide(isLong: false), OrderSide.buy);
    });
  });

  group('closeOrderQty', () {
    test('Bybit and Bitget size in base units, no contract conversion', () {
      expect(
        closeOrderQty(
          size: 0.35,
          exchange: ExchangeId.bybit,
          contractSize: 1,
          qtyStep: 0.01,
        ),
        closeTo(0.35, 1e-9),
      );
      expect(
        closeOrderQty(size: 12, exchange: ExchangeId.bitget, qtyStep: 1),
        12,
      );
    });

    test('Gate and MEXC convert base units to contracts', () {
      expect(
        closeOrderQty(
          size: 50,
          exchange: ExchangeId.gate,
          contractSize: 10,
          qtyStep: 1,
        ),
        5,
      );
      expect(
        closeOrderQty(
          size: 0.03,
          exchange: ExchangeId.mexc,
          contractSize: 0.001,
          qtyStep: 1,
        ),
        30,
      );
    });

    test('OKX size is already a contract count and is left alone', () {
      expect(
        closeOrderQty(
          size: 3,
          exchange: ExchangeId.okx,
          contractSize: 0.01,
          qtyStep: 1,
        ),
        3,
      );
    });

    test('floors to the step, leaving at most one step of dust', () {
      expect(
        closeOrderQty(size: 0.157, exchange: ExchangeId.bybit, qtyStep: 0.01),
        closeTo(0.15, 1e-9),
      );
    });

    test('returns 0 when nothing placeable remains', () {
      expect(
        closeOrderQty(
          size: 0.004,
          exchange: ExchangeId.bybit,
          qtyStep: 0.001,
          minQty: 0.01,
        ),
        0,
      );
      expect(closeOrderQty(size: 0, exchange: ExchangeId.bybit), 0);
      expect(
        closeOrderQty(size: 5, exchange: ExchangeId.gate, contractSize: 0),
        0,
      );
    });
  });

  group('makerLimitPrice', () {
    const quote = Quote(bid: 61990, ask: 62000, last: 61995);

    test('closing a long rests at the ask, rounded up off the spread', () {
      expect(
        makerLimitPrice(quote: quote, isLong: true, tickSize: 0.5),
        62000,
      );
      expect(
        makerLimitPrice(
          quote: const Quote(bid: 61990, ask: 62000.3, last: 61995),
          isLong: true,
          tickSize: 0.5,
        ),
        62000.5,
      );
    });

    test('closing a short rests at the bid, rounded down off the spread', () {
      expect(
        makerLimitPrice(
          quote: const Quote(bid: 61990.7, ask: 62000, last: 61995),
          isLong: false,
          tickSize: 0.5,
        ),
        61990.5,
      );
    });

    test('falls back to the mid when the book side is missing', () {
      expect(
        makerLimitPrice(
          quote: const Quote(bid: 0, ask: 0, last: 100),
          isLong: false,
        ),
        100,
      );
    });
  });

  group('takerLimitPrice', () {
    test('crosses down to close a long and up to close a short', () {
      expect(
        takerLimitPrice(
          refPrice: 62000,
          isLong: true,
          bufferPct: 0.3,
          tickSize: 0.5,
        ),
        61814,
      );
      expect(
        takerLimitPrice(
          refPrice: 62000,
          isLong: false,
          bufferPct: 0.3,
          tickSize: 0.5,
        ),
        62186,
      );
    });

    test('tick rounding never eats into the buffer', () {
      final sell = takerLimitPrice(
        refPrice: 100,
        isLong: true,
        bufferPct: 0.3,
        tickSize: 0.5,
      );
      final buy = takerLimitPrice(
        refPrice: 100,
        isLong: false,
        bufferPct: 0.3,
        tickSize: 0.5,
      );

      expect(sell, lessThanOrEqualTo(99.7));
      expect(buy, greaterThanOrEqualTo(100.3));
    });
  });

  group('abandonedByTicks', () {
    test('counts ticks only when the market leaves the order behind', () {
      // Resting sell at 62000, ask has fallen to 61995: 10 ticks behind.
      expect(
        abandonedByTicks(
          placedPrice: 62000,
          quote: const Quote(bid: 61994, ask: 61995, last: 61995),
          isLong: true,
          tickSize: 0.5,
        ),
        closeTo(10, 1e-9),
      );
      // Resting buy at 61990, bid has risen to 61995: 10 ticks behind.
      expect(
        abandonedByTicks(
          placedPrice: 61990,
          quote: const Quote(bid: 61995, ask: 61996, last: 61995),
          isLong: false,
          tickSize: 0.5,
        ),
        closeTo(10, 1e-9),
      );
    });

    test('a market coming toward the order is not a reason to re-price', () {
      expect(
        abandonedByTicks(
          placedPrice: 62000,
          quote: const Quote(bid: 62050, ask: 62060, last: 62055),
          isLong: true,
          tickSize: 0.5,
        ),
        0,
      );
    });

    test('reports 0 when the tick size is unknown', () {
      expect(
        abandonedByTicks(
          placedPrice: 62000,
          quote: const Quote(bid: 100, ask: 101, last: 100),
          isLong: true,
        ),
        0,
      );
    });
  });
}
