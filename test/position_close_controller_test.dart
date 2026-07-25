import 'package:core/core.dart';
import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/market_data_registry.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
import 'package:crypto_position/src/trade/position_close_controller.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// One recorded order.
typedef PlacedOrder = ({
  OrderSide side,
  double qty,
  double price,
  bool postOnly,
  bool reduceOnly,
});

class FakeExecutor implements TradeExecutor {
  /// Rejects post-only orders, standing in for a book that moved under them.
  bool rejectPostOnly;

  /// Rejects crossing orders too.
  bool rejectTaker;

  final List<PlacedOrder> placed = [];
  final List<String> canceled = [];
  int _seq = 0;

  FakeExecutor({this.rejectPostOnly = false, this.rejectTaker = false});

  /// Runs after every accepted order, so a test can close the position at the
  /// exact moment a given order lands.
  void Function(PlacedOrder order)? onPlaced;

  @override
  Future<Result<OrderAck, Object>> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double qty,
    required double price,
    bool postOnly = false,
    bool reduceOnly = false,
  }) async {
    final order = (
      side: side,
      qty: qty,
      price: price,
      postOnly: postOnly,
      reduceOnly: reduceOnly,
    );
    placed.add(order);
    if (postOnly && rejectPostOnly) return const Err('post-only would cross');
    if (!postOnly && rejectTaker) return const Err('rejected');
    onPlaced?.call(order);
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
  Future<Result<void, Object>> cancelAll(String symbol) async => const Ok(null);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async =>
      const Ok(ApiKeyPermissions(canTrade: true));

  @override
  Future<Result<void, Object>> setLeverage(String symbol, double leverage) async =>
      const Ok(null);

  @override
  Future<Result<void, Object>> ensureOneWayMode(String symbol) async =>
      const Ok(null);
}

/// Holds one position that tests shrink or clear to simulate fills.
class FakeAccountRepository implements ExchangeAccountRepository {
  final ValueNotifier<List<PositionModel>?> _positions;

  FakeAccountRepository(PositionModel? position)
    : _positions = ValueNotifier(position == null ? [] : [position]);

  int fetchPositionsCount = 0;

  void setSize(double size) {
    final current = _positions.value!.first;
    _positions.value = size <= 0 ? [] : [current.copyWith(size: size)];
  }

  @override
  ValueListenable<List<PositionModel>?> get positions => _positions;

  @override
  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    fetchPositionsCount++;
    return Ok(_positions.value ?? const []);
  }

  @override
  ValueListenable<BalanceModel?> get balance => ValueNotifier(null);

  @override
  Future<Result<BalanceModel, Object>> fetchBalance() async =>
      const Err('unused');

  @override
  void dispose() {}
}

/// Serves a fixed instrument and a quote the test can move.
class FakeMarketData implements MarketDataProvider {
  @override
  final ExchangeId exchange;

  final PerpInstrument instrument;
  Quote quote;

  FakeMarketData({
    required this.exchange,
    required this.instrument,
    required this.quote,
  });

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async => [instrument];

  @override
  Future<Quote> fetchQuote(String symbol) async => quote;

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async =>
      const OrderBook(bids: [], asks: []);

  @override
  Future<FundingInfo> fetchFunding(String symbol) async =>
      const FundingInfo(rate: 0, intervalHours: 8);

  @override
  Future<List<Candle>> fetchKlines(
    String symbol, {
    int intervalMinutes = 1,
    int limit = 60,
  }) async => const [];
}

class FakePrefs implements SharedPreferencesHelper {
  @override
  Future<double> getDouble(String key, double defaultValue) async =>
      defaultValue;

  @override
  Future<bool> getBool(String key, bool defaultValue) async => defaultValue;

  @override
  Future<int> getInt(String key, int defaultValue) async => defaultValue;

  @override
  Future<String> getString(String key, String defaultValue) async =>
      defaultValue;

  @override
  Future<List<String>> getStringList(
    String key,
    List<String> defaultValue,
  ) async => defaultValue;

  @override
  Future<void> set(String key, Object value) async {}

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<Iterable<String>> allKeys() async => const [];

  @override
  Future<bool> containsKey(String key) async => false;
}

const _symbol = 'BTCUSDT';

PositionModel _position({String side = 'Buy', double size = 0.1}) =>
    PositionModel(
      symbol: _symbol,
      side: side,
      size: size,
      avgPrice: 60000,
      markPrice: 62000,
      unrealisedPnl: 0,
      leverage: 10,
    );

const _instrument = PerpInstrument(
  exchange: ExchangeId.bybit,
  symbol: _symbol,
  base: 'BTC',
  quote: 'USDT',
  qtyStep: 0.001,
  minQty: 0.001,
  tickSize: 0.5,
  contractSize: 1,
);

class _Harness {
  final FakeExecutor executor;
  final FakeAccountRepository repository;
  final FakeMarketData market;
  final PositionCloseController controller;

  _Harness({
    required this.executor,
    required this.repository,
    required this.market,
    required this.controller,
  });
}

_Harness _harness({
  PositionModel? position,
  Quote quote = const Quote(bid: 61990, ask: 62000, last: 61995),
  bool rejectPostOnly = false,
  bool rejectTaker = false,
  bool withSession = true,
  CloseTuning tuning = const CloseTuning(
    makerWait: Duration(seconds: 3),
    takerWait: Duration(seconds: 3),
    maxRepriceAttempts: 3,
  ),
}) {
  final executor = FakeExecutor(
    rejectPostOnly: rejectPostOnly,
    rejectTaker: rejectTaker,
  );
  final repository = FakeAccountRepository(position ?? _position());
  final market = FakeMarketData(
    exchange: ExchangeId.bybit,
    instrument: _instrument,
    quote: quote,
  );

  return _Harness(
    executor: executor,
    repository: repository,
    market: market,
    controller: PositionCloseController(
      executors: TradeExecutorRegistry({
        ExchangeId.bybit: () => withSession ? executor : null,
      }),
      accounts: ExchangeAccountRegistry({
        ExchangeId.bybit: () => withSession ? repository : null,
      }),
      market: MarketDataRegistry(
        providers: {ExchangeId.bybit: market},
        connectedFlags: {ExchangeId.bybit: ValueNotifier(true)},
      ),
      fees: FeeSettingsStore(FakePrefs()),
      tuning: tuning,
      // No real waiting: the loop accounts for elapsed time itself.
      delay: (_) async {},
    ),
  );
}

void main() {
  group('plan', () {
    test('prices a long exit as a post-only sell at the ask', () async {
      final h = _harness();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);

      expect(items.single.valid, isTrue);
      expect(items.single.orderSide, OrderSide.sell);
      expect(items.single.qty, closeTo(0.1, 1e-9));
      expect(items.single.makerPrice, 62000);
      // 0.1 * 62000 * 0.02% maker
      expect(items.single.estFeeUsd, closeTo(1.24, 1e-9));
    });

    test('prices a short exit as a buy at the bid', () async {
      final h = _harness(position: _position(side: 'Sell'));

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position(side: 'Sell')),
      ]);

      expect(items.single.orderSide, OrderSide.buy);
      expect(items.single.makerPrice, 61990);
    });

    test('refuses a position whose side it cannot read', () async {
      final h = _harness();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position(side: 'net')),
      ]);

      expect(items.single.valid, isFalse);
      expect(items.single.invalidReason, contains('неизвестная сторона'));
    });

    test('refuses a position with no active session', () async {
      final h = _harness(withSession: false);

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);

      expect(items.single.invalidReason, 'нет активной сессии');
    });

    test('refuses a size below the exchange minimum', () async {
      final h = _harness();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position(size: 0.0004)),
      ]);

      expect(items.single.invalidReason, 'объём ниже минимума биржи');
    });
  });

  group('run', () {
    test('a maker fill closes the position without crossing the book', () async {
      final h = _harness();
      // The post-only order fills as soon as it rests.
      h.executor.onPlaced = (_) => h.repository.setSize(0);

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isTrue);
      expect(report.items.single.tookLiquidity, isFalse);
      expect(h.executor.placed, hasLength(1));
      expect(h.executor.placed.single.postOnly, isTrue);
      expect(h.executor.placed.single.reduceOnly, isTrue);
      expect(h.executor.placed.single.side, OrderSide.sell);
    });

    test('re-prices when the market leaves the resting order behind', () async {
      final h = _harness();
      // First order rests at the ask; then the ask falls far below it.
      h.executor.onPlaced = (order) {
        if (h.executor.placed.length == 1) {
          h.market.quote = const Quote(bid: 61890, ask: 61900, last: 61895);
        } else {
          h.repository.setSize(0);
        }
      };

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isTrue);
      expect(h.executor.placed, hasLength(2));
      expect(h.executor.placed[0].price, 62000);
      expect(h.executor.placed[1].price, 61900);
      expect(h.executor.placed.every((o) => o.postOnly), isTrue);
      // The abandoned order is pulled before the replacement goes in.
      expect(h.executor.canceled.first, 'o0');
    });

    test('crosses the book once the post-only attempts run out', () async {
      final h = _harness();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      // 3 post-only attempts, then exactly one crossing order.
      final postOnly = h.executor.placed.where((o) => o.postOnly).toList();
      final crossing = h.executor.placed.where((o) => !o.postOnly).toList();
      expect(postOnly, hasLength(3));
      expect(crossing, hasLength(1));
      // Sell 0.3% below the mid (61995), rounded down to the tick.
      expect(crossing.single.price, 61809);
      expect(crossing.single.reduceOnly, isTrue);
      // Nothing ever filled, so the exit is reported as incomplete.
      expect(report.ok, isFalse);
      expect(report.items.single.tookLiquidity, isTrue);
      expect(report.items.single.remainingQty, closeTo(0.1, 1e-9));
      expect(report.items.single.message, contains('не полностью'));
    });

    test('a rejected post-only order is retried, then crosses', () async {
      final h = _harness(rejectPostOnly: true);
      h.executor.onPlaced = (order) {
        // Only the crossing order fills.
        if (!order.postOnly) h.repository.setSize(0);
      };

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(h.executor.placed.where((o) => o.postOnly), hasLength(3));
      expect(h.executor.placed.where((o) => !o.postOnly), hasLength(1));
      expect(report.ok, isTrue);
      expect(report.items.single.tookLiquidity, isTrue);
    });

    test('re-sizes to the remainder after a partial fill', () async {
      final h = _harness();
      h.executor.onPlaced = (_) {
        if (h.executor.placed.length == 1) {
          h.repository.setSize(0.04);
        } else {
          h.repository.setSize(0);
        }
      };

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isTrue);
      expect(h.executor.placed[0].qty, closeTo(0.1, 1e-9));
      expect(h.executor.placed[1].qty, closeTo(0.04, 1e-9));
    });

    test('reports a rejected crossing order instead of looping', () async {
      final h = _harness(rejectPostOnly: true, rejectTaker: true);

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isFalse);
      expect(report.items.single.message, contains('отклонён'));
      expect(h.executor.placed.where((o) => !o.postOnly), hasLength(1));
    });

    test('abort cancels the resting order and leaves the position', () async {
      final h = _harness();
      h.executor.onPlaced = (_) => h.controller.abort();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isFalse);
      expect(h.executor.placed, hasLength(1));
      expect(h.executor.canceled, hasLength(1));
      expect(report.items.single.message, contains('остановлен'));
      expect(report.items.single.remainingQty, closeTo(0.1, 1e-9));
    });

    test('carries an invalid item into the report without ordering', () async {
      final h = _harness();

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position(side: 'net')),
      ]);
      final report = await h.controller.run(items);

      expect(report.ok, isFalse);
      expect(h.executor.placed, isEmpty);
      expect(report.items.single.message, contains('неизвестная сторона'));
    });

    test('reports progress phases in order', () async {
      final h = _harness(rejectPostOnly: true);
      h.executor.onPlaced = (order) {
        if (!order.postOnly) h.repository.setSize(0);
      };
      final phases = <ClosePhase>[];

      final items = await h.controller.plan([
        (exchange: ExchangeId.bybit, position: _position()),
      ]);
      await h.controller.run(items, onProgress: (p) => phases.add(p.phase));

      expect(phases.first, ClosePhase.maker);
      expect(phases, contains(ClosePhase.chasing));
      expect(phases, contains(ClosePhase.taker));
      expect(phases.last, ClosePhase.done);
    });
  });
}
