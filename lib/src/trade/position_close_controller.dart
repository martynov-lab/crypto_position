import 'package:core/core.dart';
import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/market_data_registry.dart';
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
import 'package:crypto_position/src/trade/position_close_math.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:exchange/exchange.dart';

/// One open position the user asked to close.
typedef PositionToClose = ({ExchangeId exchange, PositionModel position});

/// Timings and limits of the close strategy. Defaults balance "fills as a maker
/// on a calm market" against "always closed within a bounded time".
class CloseTuning {
  /// How long a post-only order is given to fill before it is re-priced.
  final Duration makerWait;

  /// How long the final crossing order is given to fill before the position is
  /// reported as not fully closed.
  final Duration takerWait;

  /// How often the position size is re-read while waiting.
  final Duration pollInterval;

  /// How far the top of the book must leave a resting order behind before it is
  /// cancelled and re-priced.
  final double repriceTicks;

  /// How many post-only attempts are made before crossing the book.
  final int maxRepriceAttempts;

  /// Total time budget for one position; crossing the book starts once it is
  /// spent, whatever the attempt count.
  final Duration deadline;

  /// How far the final order crosses the book, in percent of the reference
  /// price.
  final double takerBufferPct;

  const CloseTuning({
    this.makerWait = const Duration(seconds: 6),
    this.takerWait = const Duration(seconds: 10),
    this.pollInterval = const Duration(seconds: 1),
    this.repriceTicks = 2,
    this.maxRepriceAttempts = 4,
    this.deadline = const Duration(seconds: 45),
    this.takerBufferPct = 0.3,
  });
}

/// A planned exit from one position: the first (maker) order that will be sent,
/// plus everything the run loop needs to re-price and re-size it.
class ClosePlanItem {
  final ExchangeId exchange;
  final String symbol;

  /// The exchange's own wording of the position side, also part of [key].
  final String side;
  final bool isLong;
  final OrderSide orderSide;

  /// Size of the first order, in the exchange's native order unit.
  final double qty;

  /// Price of the first (post-only) order.
  final double makerPrice;

  /// Maker fee this exit would cost at [qty]/[makerPrice], in USDT.
  final double estFeeUsd;

  final double? tickSize;
  final double? qtyStep;
  final double? minQty;
  final double? contractSize;

  /// Null when the exit can be attempted; otherwise why it cannot.
  final String? invalidReason;

  const ClosePlanItem({
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.isLong,
    required this.orderSide,
    required this.qty,
    required this.makerPrice,
    required this.estFeeUsd,
    this.tickSize,
    this.qtyStep,
    this.minQty,
    this.contractSize,
    this.invalidReason,
  });

  bool get valid => invalidReason == null;

  String get key => '${exchange.key}|$symbol|$side';
}

/// Where one position's exit currently is.
enum ClosePhase {
  /// A post-only order is resting on the book.
  maker,

  /// The resting order was left behind and is being re-priced.
  chasing,

  /// A crossing order was sent to guarantee the exit.
  taker,

  /// The position is gone.
  done,

  /// The exit ended with size still open.
  failed,

  /// The user stopped the exit.
  aborted,
}

/// A progress tick for one position, pushed to the UI as the exit runs.
class CloseProgress {
  final ExchangeId exchange;
  final String symbol;
  final String side;
  final ClosePhase phase;

  /// 1-based post-only attempt number.
  final int attempt;

  /// Position size still open, in the exchange's native order unit.
  final double remainingQty;

  final String? message;

  const CloseProgress({
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.phase,
    required this.attempt,
    required this.remainingQty,
    this.message,
  });

  String get key => '${exchange.key}|$symbol|$side';
}

/// How one position's exit ended.
class CloseOutcome {
  final ExchangeId exchange;
  final String symbol;
  final String side;

  /// True only when the position is fully closed.
  final bool ok;

  /// True when the exit had to cross the book, paying the taker fee.
  final bool tookLiquidity;

  /// Size left open, in the exchange's native order unit. 0 when [ok].
  final double remainingQty;

  final String? message;

  const CloseOutcome({
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.ok,
    this.tookLiquidity = false,
    this.remainingQty = 0,
    this.message,
  });

  String get key => '${exchange.key}|$symbol|$side';
}

class CloseReport {
  final List<CloseOutcome> items;

  const CloseReport(this.items);

  bool get ok => items.isNotEmpty && items.every((i) => i.ok);

  /// Positions that ended with size still open.
  List<CloseOutcome> get unclosed => items.where((i) => !i.ok).toList();
}

/// Closes open positions with a reduce-only limit order, maker-first.
///
/// Each position runs its own loop: rest a post-only order at the top of the
/// book (maker fee), re-price it whenever the market leaves it behind, and once
/// the attempts or the time budget are spent, cross the book to guarantee the
/// exit. Fills are detected from the account's own position size — which the
/// account WS stream already keeps live — rather than from an order-status
/// endpoint, so a partial fill simply shrinks the next order.
///
/// Positions are closed in parallel: an arbitrage pair must not have one leg
/// waiting on the other's maker fill any longer than necessary.
class PositionCloseController {
  final TradeExecutorRegistry _executors;
  final ExchangeAccountRegistry _accounts;
  final MarketDataRegistry _market;
  final FeeSettingsStore _fees;

  final CloseTuning tuning;

  /// Injected so tests can run the loop without real waiting.
  final Future<void> Function(Duration) _delay;

  var _aborted = false;

  PositionCloseController({
    required TradeExecutorRegistry executors,
    required ExchangeAccountRegistry accounts,
    required MarketDataRegistry market,
    required FeeSettingsStore fees,
    this.tuning = const CloseTuning(),
    Future<void> Function(Duration)? delay,
  }) : _executors = executors,
       _accounts = accounts,
       _market = market,
       _fees = fees,
       _delay = delay ?? Future<void>.delayed;

  /// Builds the exit plan for [positions], resolving each instrument's tick and
  /// size filters and the price the first order would rest at. Never places
  /// anything.
  Future<List<ClosePlanItem>> plan(List<PositionToClose> positions) =>
      Future.wait(positions.map(_planOne));

  Future<ClosePlanItem> _planOne(PositionToClose target) async {
    final exchange = target.exchange;
    final position = target.position;

    ClosePlanItem invalid(String reason, {bool? isLong}) => ClosePlanItem(
      exchange: exchange,
      symbol: position.symbol,
      side: position.side,
      isLong: isLong ?? true,
      orderSide: closeOrderSide(isLong: isLong ?? true),
      qty: 0,
      makerPrice: 0,
      estFeeUsd: 0,
      invalidReason: reason,
    );

    final isLong = positionIsLong(position.side);
    if (isLong == null) {
      return invalid('неизвестная сторона позиции «${position.side}»');
    }
    if (_executors.executor(exchange) == null) {
      return invalid('нет активной сессии', isLong: isLong);
    }

    final instrument = await _instrument(exchange, position.symbol);
    if (instrument == null) {
      return invalid('инструмент не найден на бирже', isLong: isLong);
    }

    final qty = closeOrderQty(
      size: position.size,
      exchange: exchange,
      contractSize: instrument.contractSize,
      qtyStep: instrument.qtyStep,
      minQty: instrument.minQty,
    );
    if (qty <= 0) {
      return invalid('объём ниже минимума биржи', isLong: isLong);
    }

    final quote = await _quote(exchange, position.symbol, position.markPrice);
    if (quote == null) {
      return invalid('нет цены по инструменту', isLong: isLong);
    }

    final price = makerLimitPrice(
      quote: quote,
      isLong: isLong,
      tickSize: instrument.tickSize,
    );
    final notional = qty * price * (instrument.contractSize ?? 1);

    return ClosePlanItem(
      exchange: exchange,
      symbol: position.symbol,
      side: position.side,
      isLong: isLong,
      orderSide: closeOrderSide(isLong: isLong),
      qty: qty,
      makerPrice: price,
      estFeeUsd: notional * _fees.makerPct(exchange) / 100,
      tickSize: instrument.tickSize,
      qtyStep: instrument.qtyStep,
      minQty: instrument.minQty,
      contractSize: instrument.contractSize,
    );
  }

  /// Runs the exit for every valid item in [items], reporting each step through
  /// [onProgress]. Invalid items are carried into the report untouched.
  Future<CloseReport> run(
    List<ClosePlanItem> items, {
    void Function(CloseProgress)? onProgress,
  }) async {
    _aborted = false;
    final outcomes = await Future.wait(
      items.map((item) => _closeOne(item, onProgress)),
    );
    return CloseReport(outcomes);
  }

  /// Stops every running exit after the current step: resting orders are
  /// cancelled and the positions are left as they are.
  void abort() => _aborted = true;

  Future<CloseOutcome> _closeOne(
    ClosePlanItem item,
    void Function(CloseProgress)? onProgress,
  ) async {
    CloseOutcome outcome(
      ClosePhase phase, {
      required bool ok,
      bool tookLiquidity = false,
      double remainingQty = 0,
      String? message,
    }) {
      onProgress?.call(
        CloseProgress(
          exchange: item.exchange,
          symbol: item.symbol,
          side: item.side,
          phase: phase,
          attempt: 0,
          remainingQty: remainingQty,
          message: message,
        ),
      );
      return CloseOutcome(
        exchange: item.exchange,
        symbol: item.symbol,
        side: item.side,
        ok: ok,
        tookLiquidity: tookLiquidity,
        remainingQty: remainingQty,
        message: message,
      );
    }

    if (!item.valid) {
      return outcome(
        ClosePhase.failed,
        ok: false,
        remainingQty: item.qty,
        message: item.invalidReason,
      );
    }

    final executor = _executors.executor(item.exchange);
    if (executor == null) {
      return outcome(
        ClosePhase.failed,
        ok: false,
        remainingQty: item.qty,
        message: 'нет активной сессии',
      );
    }

    // Waiting is accumulated by hand rather than read off a clock, so the
    // deadline behaves identically under an injected (instant) delay in tests.
    var elapsed = Duration.zero;
    Future<void> wait(Duration d) async {
      await _delay(d);
      elapsed += d;
    }

    var attempt = 0;
    var taker = false;
    var everTookLiquidity = false;
    var remaining = item.qty;

    while (true) {
      if (_aborted) {
        return outcome(
          ClosePhase.aborted,
          ok: false,
          tookLiquidity: everTookLiquidity,
          remainingQty: remaining,
          message: 'выход остановлен пользователем',
        );
      }

      final open = await _remainingQty(item);
      if (open == null) {
        return outcome(
          ClosePhase.failed,
          ok: false,
          tookLiquidity: everTookLiquidity,
          remainingQty: remaining,
          message: 'нет активной сессии',
        );
      }
      if (open <= 0) {
        return outcome(
          ClosePhase.done,
          ok: true,
          tookLiquidity: everTookLiquidity,
        );
      }
      remaining = open;

      final quote = await _quote(item.exchange, item.symbol, null);
      if (quote == null) {
        return outcome(
          ClosePhase.failed,
          ok: false,
          tookLiquidity: everTookLiquidity,
          remainingQty: remaining,
          message: 'нет цены по инструменту',
        );
      }

      final price = taker
          ? takerLimitPrice(
              refPrice: quote.mid,
              isLong: item.isLong,
              bufferPct: tuning.takerBufferPct,
              tickSize: item.tickSize,
            )
          : makerLimitPrice(
              quote: quote,
              isLong: item.isLong,
              tickSize: item.tickSize,
            );

      onProgress?.call(
        CloseProgress(
          exchange: item.exchange,
          symbol: item.symbol,
          side: item.side,
          phase: taker
              ? ClosePhase.taker
              : (attempt == 0 ? ClosePhase.maker : ClosePhase.chasing),
          attempt: attempt + 1,
          remainingQty: remaining,
        ),
      );

      final placed = await executor.placeLimitOrder(
        symbol: item.symbol,
        side: item.orderSide,
        qty: remaining,
        price: price,
        postOnly: !taker,
        reduceOnly: true,
      );

      if (placed case Err(:final error)) {
        if (taker) {
          return outcome(
            ClosePhase.failed,
            ok: false,
            tookLiquidity: everTookLiquidity,
            remainingQty: remaining,
            message: 'ордер отклонён: $error',
          );
        }
        // A post-only order is rejected when it would cross, i.e. the book
        // moved between the quote and the order. Retry with a fresh quote; the
        // attempt still counts so a fast market ends up crossing the book.
        attempt++;
        if (attempt >= tuning.maxRepriceAttempts || elapsed >= tuning.deadline) {
          taker = true;
        }
        continue;
      }

      if (taker) everTookLiquidity = true;
      final orderId = (placed as Ok<OrderAck, Object>).value.orderId;
      final window = taker ? tuning.takerWait : tuning.makerWait;
      var waited = Duration.zero;

      while (waited < window) {
        await wait(tuning.pollInterval);
        waited += tuning.pollInterval;

        if (_aborted) break;
        final left = await _remainingQty(item);
        if (left != null && left <= 0) {
          await _cancelQuietly(executor, item.symbol, orderId);
          return outcome(
            ClosePhase.done,
            ok: true,
            tookLiquidity: everTookLiquidity,
          );
        }
        if (taker) continue;

        final fresh = await _quote(item.exchange, item.symbol, null);
        if (fresh == null) continue;
        final behind = abandonedByTicks(
          placedPrice: price,
          quote: fresh,
          isLong: item.isLong,
          tickSize: item.tickSize,
        );
        // Left behind by the market: re-price now instead of sitting out the
        // rest of the window.
        if (behind >= tuning.repriceTicks) break;
      }

      await _cancelQuietly(executor, item.symbol, orderId);

      // The cancel races the fill, so the position is the authority on whether
      // anything is left.
      remaining = await _remainingQty(item) ?? remaining;
      if (remaining <= 0) {
        return outcome(
          ClosePhase.done,
          ok: true,
          tookLiquidity: everTookLiquidity,
        );
      }

      if (_aborted) {
        return outcome(
          ClosePhase.aborted,
          ok: false,
          tookLiquidity: everTookLiquidity,
          remainingQty: remaining,
          message: 'выход остановлен пользователем',
        );
      }

      if (taker) {
        return outcome(
          ClosePhase.failed,
          ok: false,
          tookLiquidity: true,
          remainingQty: remaining,
          message: 'позиция закрыта не полностью — проверьте её на бирже',
        );
      }

      // Out of post-only attempts, or out of time: cross the book, which is the
      // only way the exit is guaranteed to complete.
      attempt++;
      if (attempt >= tuning.maxRepriceAttempts || elapsed >= tuning.deadline) {
        taker = true;
      }
    }
  }

  /// Cancels a resting order, ignoring the error: the only way this fails in
  /// practice is the order already being gone (filled or cancelled), which the
  /// position re-read right after settles anyway.
  Future<void> _cancelQuietly(
    TradeExecutor executor,
    String symbol,
    String orderId,
  ) async {
    await executor.cancelOrder(symbol: symbol, orderId: orderId);
  }

  /// The position's still-open size in the exchange's native order unit, 0 when
  /// it is gone and null when it can't be told (no session), which must never be
  /// read as "closed".
  ///
  /// Reads the WS-backed snapshot first and confirms a zero over REST before
  /// declaring the exit finished. A row only disappears from the snapshot on a
  /// zero-size frame, so a live 0 is trustworthy on its own — the re-read just
  /// covers a stale snapshot behind a dropped WS connection, and its own failure
  /// therefore falls back to the snapshot.
  Future<double?> _remainingQty(ClosePlanItem item) async {
    final repo = _accounts.repository(item.exchange);
    if (repo == null) return null;

    var size = _sizeFrom(repo.positions.value, item);
    if (size <= 0) {
      final refreshed = await repo.fetchPositions();
      if (refreshed case Ok(:final value)) {
        size = _sizeFrom(value, item);
      } else {
        return 0;
      }
      if (size <= 0) return 0;
    }

    return closeOrderQty(
      size: size,
      exchange: item.exchange,
      contractSize: item.contractSize,
      qtyStep: item.qtyStep,
      minQty: item.minQty,
    );
  }

  static double _sizeFrom(List<PositionModel>? positions, ClosePlanItem item) {
    for (final position in positions ?? const <PositionModel>[]) {
      if (position.symbol == item.symbol && position.side == item.side) {
        return position.size.abs();
      }
    }
    return 0;
  }

  /// The instrument's filters, or null when the exchange has no provider or the
  /// symbol is absent from its perpetual list.
  Future<PerpInstrument?> _instrument(ExchangeId exchange, String symbol) async {
    final provider = _market.provider(exchange);
    if (provider == null) return null;
    try {
      final instruments = await provider.fetchPerpInstruments();
      for (final instrument in instruments) {
        if (instrument.symbol == symbol) return instrument;
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// Live top of book, falling back to [markPrice] when the public quote can't
  /// be read (the mark is enough to price a crossing order).
  Future<Quote?> _quote(
    ExchangeId exchange,
    String symbol,
    double? markPrice,
  ) async {
    final provider = _market.provider(exchange);
    if (provider != null) {
      try {
        final quote = await provider.fetchQuote(symbol);
        if (quote.mid > 0) return quote;
      } on Object {
        // Falls through to the mark price below.
      }
    }
    if (markPrice != null && markPrice > 0) {
      return Quote(bid: markPrice, ask: markPrice, last: markPrice);
    }
    return null;
  }
}
