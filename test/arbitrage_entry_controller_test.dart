import 'package:core/core.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/trade/arbitrage_entry_controller.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records calls and returns configurable results.
class FakeExecutor implements TradeExecutor {
  bool canTrade;
  bool permsError;

  /// When true, rejects real entry orders (post-only canary and reduce-only
  /// unwind orders still succeed).
  bool failEntry;

  final List<({OrderSide side, bool postOnly, bool reduceOnly})> placed = [];
  final List<String> canceled = [];
  int cancelAllCount = 0;
  int _seq = 0;

  FakeExecutor({
    this.canTrade = true,
    this.permsError = false,
    this.failEntry = false,
  });

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async =>
      permsError
          ? const Err('perms boom')
          : Ok(ApiKeyPermissions(canTrade: canTrade));

  @override
  Future<Result<void, Object>> setLeverage(String symbol, double leverage) async =>
      const Ok(null);

  @override
  Future<Result<OrderAck, Object>> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double qty,
    required double price,
    bool postOnly = false,
    bool reduceOnly = false,
  }) async {
    placed.add((side: side, postOnly: postOnly, reduceOnly: reduceOnly));
    if (failEntry && !postOnly && !reduceOnly) return const Err('rejected');
    return Ok(OrderAck(orderId: 'o${_seq++}'));
  }

  @override
  Future<Result<void, Object>> cancelOrder({
    required String symbol,
    required String orderId,
  }) async {
    canceled.add(orderId);
    return const Ok(null);
  }

  @override
  Future<Result<void, Object>> cancelAll(String symbol) async {
    cancelAllCount++;
    return const Ok(null);
  }
}

EntryPlan _plan() => const EntryPlan(
      long: EntryLeg(
        exchange: ExchangeId.bybit,
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        qty: 1,
        price: 100,
        minQty: 0.001,
        refPrice: 100,
      ),
      short: EntryLeg(
        exchange: ExchangeId.okx,
        symbol: 'BTC-USDT-SWAP',
        side: OrderSide.sell,
        qty: 1,
        price: 101,
        minQty: 1,
        refPrice: 101,
      ),
    );

ArbitrageEntryController _controller(FakeExecutor long, FakeExecutor short) {
  return ArbitrageEntryController(
    TradeExecutorRegistry({
      ExchangeId.bybit: () => long,
      ExchangeId.okx: () => short,
    }),
  );
}

void main() {
  group('runCanary', () {
    test('places a post-only probe and cancels it when the key can trade',
        () async {
      final long = FakeExecutor();
      final short = FakeExecutor();
      final report = await _controller(long, short).runCanary(_plan());

      expect(report.ok, isTrue);
      expect(long.placed.single.postOnly, isTrue);
      expect(long.canceled, hasLength(1));
      expect(long.cancelAllCount, 1);
    });

    test('fails the leg whose key cannot trade, placing no order', () async {
      final long = FakeExecutor();
      final short = FakeExecutor(canTrade: false);
      final report = await _controller(long, short).runCanary(_plan());

      expect(report.ok, isFalse);
      expect(short.placed, isEmpty);
    });
  });

  group('execute', () {
    test('both legs accepted opens the position with no unwind', () async {
      final long = FakeExecutor();
      final short = FakeExecutor();
      final report =
          await _controller(long, short).execute(_plan(), leverage: 5);

      expect(report.ok, isTrue);
      expect(report.unwound, isFalse);
      expect(long.placed.single.reduceOnly, isFalse);
      expect(short.placed.single.reduceOnly, isFalse);
    });

    test('one-sided fill unwinds the placed leg with a reduce-only close',
        () async {
      final long = FakeExecutor();
      final short = FakeExecutor(failEntry: true);
      final report =
          await _controller(long, short).execute(_plan(), leverage: 5);

      expect(report.ok, isFalse);
      expect(report.unwound, isTrue);
      // Long leg: entry buy, then a reduce-only sell to flatten.
      expect(long.placed, hasLength(2));
      expect(long.placed.last.reduceOnly, isTrue);
      expect(long.placed.last.side, OrderSide.sell);
      expect(long.canceled, isNotEmpty);
    });

    test('both legs rejected leaves nothing open and does not unwind',
        () async {
      final long = FakeExecutor(failEntry: true);
      final short = FakeExecutor(failEntry: true);
      final report =
          await _controller(long, short).execute(_plan(), leverage: 5);

      expect(report.ok, isFalse);
      expect(report.unwound, isFalse);
      // Only the entry attempts; no reduce-only unwind on either side.
      expect(long.placed.every((o) => !o.reduceOnly), isTrue);
      expect(short.placed.every((o) => !o.reduceOnly), isTrue);
    });
  });
}
