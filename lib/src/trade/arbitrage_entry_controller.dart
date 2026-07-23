import 'package:core/core.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
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

  /// Size of the canary probe, in the native unit. Sized to clear both the
  /// exchange's minimum quantity and its minimum order value at [canaryPrice].
  final double canaryQty;

  /// Limit price of the canary probe: far from the market, so it cannot fill.
  final double canaryPrice;

  /// Reference (mid) price, used to price the unwind order.
  final double refPrice;

  /// Native-unit → base-asset multiplier (e.g. OKX/Gate contracts). Needed to
  /// turn [qty]×[price] into a USDT notional for the margin check; `1` when
  /// the exchange quotes directly in base units.
  final double contractSize;

  /// Null when the leg is placeable; otherwise why it is not.
  final String? invalidReason;

  const EntryLeg({
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.qty,
    required this.price,
    required this.canaryQty,
    required this.canaryPrice,
    required this.refPrice,
    this.contractSize = 1,
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
///
/// Both the canary and the real entry also check each leg's account balance
/// against the notional/leverage being requested (see [_insufficientMarginReason])
/// — this is what previously let one leg fill while the other was rejected by
/// the exchange itself for insufficient balance, forcing a same-instant
/// unwind of the leg that did land.
class ArbitrageEntryController {
  final TradeExecutorRegistry _registry;
  final ExchangeAccountRegistry _accounts;

  /// Cushion added on top of the raw notional/leverage margin requirement —
  /// covers taker fees, funding carry and price drift between this check and
  /// the actual fill.
  static const _marginSafetyMult = 1.05;

  ArbitrageEntryController(this._registry, this._accounts);

  /// The live executor for [exchange], or null when no session is active.
  /// Used by callers to gate the entry UI before building a plan.
  TradeExecutor? executorFor(ExchangeId exchange) =>
      _registry.executor(exchange);

  /// Probes each leg's exchange: confirms the key can trade and the account
  /// has enough balance for the requested size/leverage, then places and
  /// immediately cancels a minimum-size limit order far from the market
  /// (post-only, so it never takes liquidity). Places nothing that could fill.
  Future<CanaryReport> runCanary(EntryPlan plan, {required double leverage}) async {
    final outcomes = await Future.wait(
      [plan.long, plan.short].map((leg) => _canaryLeg(leg, leverage)),
    );
    return CanaryReport(outcomes);
  }

  Future<LegOutcome> _canaryLeg(EntryLeg leg, double leverage) async {
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

    // Checked here too (not just in execute()) so "Проверить" surfaces an
    // insufficient-balance situation before the user risks capital on it.
    final marginReason = await _insufficientMarginReason(leg, leverage);
    if (marginReason != null) {
      return LegOutcome(exchange: leg.exchange, ok: false, message: marginReason);
    }

    // Best-effort: hedge-mode accounts reject the one-way-shaped orders below,
    // so try to switch. A failure (e.g. open positions) is left for the probe
    // order to surface as the real error.
    await executor.ensureOneWayMode(leg.symbol);

    // A non-marketable probe, pre-sized to clear the exchange's minimum
    // quantity and minimum order value (see `canaryOrder`).
    final placed = await executor.placeLimitOrder(
      symbol: leg.symbol,
      side: leg.side,
      qty: leg.canaryQty,
      price: leg.canaryPrice,
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

  /// Checks [leg]'s exchange account balance against the margin the plan
  /// would need at [leverage]. Returns a reason string when insufficient,
  /// `null` when OK (or when it cannot be verified — a transient
  /// balance-fetch error should not by itself block the user; the exchange's
  /// own order-placement check remains the final authority).
  ///
  /// This is an approximation: it compares against the account's total USDT
  /// wallet balance, not a true "free margin" figure, so it does not account
  /// for margin already locked by other open positions on the same account.
  Future<String?> _insufficientMarginReason(EntryLeg leg, double leverage) async {
    if (leverage <= 0) return null;
    final repo = _accounts.repository(leg.exchange);
    if (repo == null) return null;
    final result = await repo.fetchBalance();
    if (result is! Ok<BalanceModel, Object>) return null;

    final available = _usdtWalletBalance(result.value);
    final notional = leg.qty * leg.price * leg.contractSize;
    final required = notional / leverage * _marginSafetyMult;
    if (available >= required) return null;
    return 'недостаточно баланса на ${leg.exchange.label}: доступно '
        '${available.toStringAsFixed(2)} USDT, нужно ~'
        '${required.toStringAsFixed(2)} USDT под плечо '
        '${leverage.toStringAsFixed(0)}x';
  }

  static double _usdtWalletBalance(BalanceModel balance) {
    for (final coin in balance.coins) {
      if (coin.coin.toUpperCase() == 'USDT') return coin.walletBalance;
    }
    return balance.totalWalletBalance;
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

    // Re-checked here (not just in the "Проверить" canary) since balance can
    // have moved since then, and this is the last point before any order is
    // placed — catches exactly the failure mode where one leg fills and the
    // other is rejected by the exchange for insufficient balance, which would
    // otherwise only surface after already needing a same-instant unwind.
    final marginReasons = await Future.wait([
      _insufficientMarginReason(plan.long, leverage),
      _insufficientMarginReason(plan.short, leverage),
    ]);
    for (var i = 0; i < marginReasons.length; i++) {
      final reason = marginReasons[i];
      if (reason != null) {
        final leg = i == 0 ? plan.long : plan.short;
        return EntryReport(
          legs: [LegOutcome(exchange: leg.exchange, ok: false, message: reason)],
          note: 'вход не начат — недостаточно баланса',
        );
      }
    }

    // Best-effort one-way mode on both legs (see _canaryLeg for rationale).
    await Future.wait([
      longExec.ensureOneWayMode(plan.long.symbol),
      shortExec.ensureOneWayMode(plan.short.symbol),
    ]);

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
