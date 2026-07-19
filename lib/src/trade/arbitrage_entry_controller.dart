import 'package:core/core.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:exchange/exchange.dart';

/// One leg of a planned arbitrage entry: what order to send on which exchange.
class EntryLeg {
  final ExchangeId exchange;
  final String symbol;
  final OrderSide side;

  /// Order size in the exchange's native unit, already rounded.
  final double qty;

  /// Limit price, already rounded to the instrument tick.
  final double price;

  /// Minimum order size in the native unit, used for the canary probe.
  final double minQty;

  /// Reference (mid) price, used to derive a non-marketable canary price.
  final double refPrice;

  /// Null when the leg is placeable; otherwise why it is not.
  final String? invalidReason;

  const EntryLeg({
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.qty,
    required this.price,
    required this.minQty,
    required this.refPrice,
    this.invalidReason,
  });

  bool get valid => invalidReason == null;
}

/// A symmetric two-leg entry: long the cheaper venue, short the dearer.
class EntryPlan {
  final EntryLeg long;
  final EntryLeg short;

  const EntryPlan({required this.long, required this.short});

  bool get valid => long.valid && short.valid;
}

/// Outcome of a single leg's canary or execution.
class LegOutcome {
  final ExchangeId exchange;
  final bool ok;
  final String? message;
  final String? orderId;

  const LegOutcome({
    required this.exchange,
    required this.ok,
    this.message,
    this.orderId,
  });
}

/// Preflight result: did each leg's key authenticate and accept a probe order.
class CanaryReport {
  final List<LegOutcome> legs;
  const CanaryReport(this.legs);
  bool get ok => legs.every((l) => l.ok);
}

/// Result of attempting the entry, including whether a one-sided fill had to be
/// unwound.
class EntryReport {
  final List<LegOutcome> legs;

  /// True when one leg placed and the other failed, and an unwind was attempted
  /// on the placed leg. The user must verify no residual position remains.
  final bool unwound;

  final String? note;

  const EntryReport({required this.legs, this.unwound = false, this.note});

  bool get ok => legs.every((l) => l.ok) && !unwound;
}

/// Drives the actual order flow for an [EntryPlan]: a zero-risk canary probe,
/// then the symmetric entry with a best-effort unwind if only one leg lands.
class ArbitrageEntryController {
  final TradeExecutorRegistry _registry;

  ArbitrageEntryController(this._registry);

  /// The live executor for [exchange], or null when no session is active.
  /// Used by callers to gate the entry UI before building a plan.
  TradeExecutor? executorFor(ExchangeId exchange) =>
      _registry.executor(exchange);

  /// Probes each leg's exchange: confirms the key can trade, then places and
  /// immediately cancels a minimum-size limit order far from the market
  /// (post-only, so it never takes liquidity). Places nothing that could fill.
  Future<CanaryReport> runCanary(EntryPlan plan) async {
    final outcomes = await Future.wait(
      [plan.long, plan.short].map(_canaryLeg),
    );
    return CanaryReport(outcomes);
  }

  Future<LegOutcome> _canaryLeg(EntryLeg leg) async {
    final executor = _registry.executor(leg.exchange);
    if (executor == null) {
      return LegOutcome(
        exchange: leg.exchange,
        ok: false,
        message: 'нет активной сессии',
      );
    }

    final perms = await executor.fetchApiPermissions();
    switch (perms) {
      case Err(:final error):
        return LegOutcome(
          exchange: leg.exchange,
          ok: false,
          message: 'ключ: $error',
        );
      case Ok(:final value):
        if (!value.canTrade) {
          return LegOutcome(
            exchange: leg.exchange,
            ok: false,
            message: 'нет права Trade',
          );
        }
    }

    // A non-marketable probe: buy far below / sell far above the market.
    final probePrice = leg.side == OrderSide.buy
        ? leg.refPrice * 0.5
        : leg.refPrice * 1.5;
    final qty = leg.minQty > 0 ? leg.minQty : leg.qty;
    final placed = await executor.placeLimitOrder(
      symbol: leg.symbol,
      side: leg.side,
      qty: qty,
      price: probePrice,
      postOnly: true,
    );

    switch (placed) {
      case Err(:final error):
        return LegOutcome(
          exchange: leg.exchange,
          ok: false,
          message: 'ордер отклонён: $error',
        );
      case Ok(:final value):
        // Clean up the probe: cancel by id, then a belt-and-braces cancel-all.
        await executor.cancelOrder(symbol: leg.symbol, orderId: value.orderId);
        await executor.cancelAll(leg.symbol);
        return LegOutcome(exchange: leg.exchange, ok: true);
    }
  }

  /// Sets leverage on both legs, then submits both limit orders as close to
  /// simultaneously as possible. If one leg is rejected while the other lands,
  /// unwinds the placed leg (cancel + reduce-only close) and flags the report.
  Future<EntryReport> execute(EntryPlan plan, {required double leverage}) async {
    final longExec = _registry.executor(plan.long.exchange);
    final shortExec = _registry.executor(plan.short.exchange);
    if (longExec == null || shortExec == null) {
      return const EntryReport(
        legs: [],
        note: 'нет активной сессии на одной из бирж',
      );
    }

    // Leverage first; a failure here means we never place an order.
    final levs = await Future.wait([
      longExec.setLeverage(plan.long.symbol, leverage),
      shortExec.setLeverage(plan.short.symbol, leverage),
    ]);
    for (var i = 0; i < levs.length; i++) {
      final r = levs[i];
      if (r is Err) {
        final leg = i == 0 ? plan.long : plan.short;
        return EntryReport(
          legs: [
            LegOutcome(
              exchange: leg.exchange,
              ok: false,
              message: 'плечо: ${(r as Err).error}',
            ),
          ],
          note: 'вход не начат — не удалось выставить плечо',
        );
      }
    }

    // Both legs at once to minimise the window where only one is live.
    final results = await Future.wait([
      longExec.placeLimitOrder(
        symbol: plan.long.symbol,
        side: OrderSide.buy,
        qty: plan.long.qty,
        price: plan.long.price,
      ),
      shortExec.placeLimitOrder(
        symbol: plan.short.symbol,
        side: OrderSide.sell,
        qty: plan.short.qty,
        price: plan.short.price,
      ),
    ]);

    final longRes = results[0];
    final shortRes = results[1];
    final longOk = longRes is Ok;
    final shortOk = shortRes is Ok;

    LegOutcome outcome(EntryLeg leg, Result<OrderAck, Object> r) => switch (r) {
      Ok(:final value) =>
        LegOutcome(exchange: leg.exchange, ok: true, orderId: value.orderId),
      Err(:final error) =>
        LegOutcome(exchange: leg.exchange, ok: false, message: '$error'),
    };

    final legs = [outcome(plan.long, longRes), outcome(plan.short, shortRes)];

    if (longOk && shortOk) {
      return EntryReport(legs: legs);
    }
    if (!longOk && !shortOk) {
      return EntryReport(
        legs: legs,
        note: 'обе ноги отклонены — позиция не открыта',
      );
    }

    // One-sided fill: unwind the leg that landed.
    final placedLeg = longOk ? plan.long : plan.short;
    final placedExec = longOk ? longExec : shortExec;
    final ack = (longOk ? longRes : shortRes) as Ok<OrderAck, Object>;
    await _unwind(placedExec, placedLeg, ack.value.orderId);

    return EntryReport(
      legs: legs,
      unwound: true,
      note: 'исполнилась только одна нога — выполнен откат; '
          'проверьте отсутствие остаточной позиции на ${placedLeg.exchange.label}',
    );
  }

  /// Best-effort flatten of a one-sided leg: cancel the resting order, then send
  /// a marketable reduce-only order in the opposite direction in case it filled.
  Future<void> _unwind(
    TradeExecutor executor,
    EntryLeg leg,
    String orderId,
  ) async {
    await executor.cancelOrder(symbol: leg.symbol, orderId: orderId);
    await executor.cancelAll(leg.symbol);
    final closeSide =
        leg.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy;
    // Cross the book to close: sell below / buy above the reference price.
    final closePrice = closeSide == OrderSide.sell
        ? leg.refPrice * 0.9
        : leg.refPrice * 1.1;
    await executor.placeLimitOrder(
      symbol: leg.symbol,
      side: closeSide,
      qty: leg.qty,
      price: closePrice,
      reduceOnly: true,
    );
  }
}
