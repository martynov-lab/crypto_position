import 'package:core/core.dart';

/// Order direction.
enum OrderSide { buy, sell }

/// Exchange acknowledgement of a submitted order.
class OrderAck {
  /// Exchange-assigned order id, used to cancel or track the order.
  final String orderId;

  /// Raw exchange order status when reported (e.g. `New`, `Filled`), else null.
  final String? status;

  const OrderAck({required this.orderId, this.status});
}

/// The trading rights of an API key, used for the preflight permission check.
class ApiKeyPermissions {
  /// True when the key is allowed to place/cancel orders.
  final bool canTrade;

  /// Raw permission descriptors as reported by the exchange, for display.
  final List<String> raw;

  const ApiKeyPermissions({required this.canTrade, this.raw = const []});
}

/// Places and cancels orders on one exchange with a signed REST client. The
/// order-placement counterpart of [ExchangeAccountRepository] (read-only). One
/// implementation per exchange; the app treats them all through this interface.
abstract interface class TradeExecutor {
  /// Reads the API key's trading rights. Zero-risk preflight — no order is
  /// placed. Part of the entry "canary" check.
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions();

  /// Sets [leverage] for [symbol] before entering a position. Idempotent on
  /// most exchanges (setting the current value is a no-op).
  Future<Result<void, Object>> setLeverage(String symbol, double leverage);

  /// Places a limit order. [qty] is in the exchange's native order unit
  /// (contracts where the exchange sizes orders in contracts, base units
  /// otherwise) and, like [price], must already be rounded to the instrument's
  /// step/tick by the caller. [postOnly] rejects orders that would take
  /// liquidity; [reduceOnly] only reduces an existing position (used to unwind).
  Future<Result<OrderAck, Object>> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double qty,
    required double price,
    bool postOnly = false,
    bool reduceOnly = false,
  });

  /// Cancels a single order by [orderId].
  Future<Result<void, Object>> cancelOrder({
    required String symbol,
    required String orderId,
  });

  /// Cancels every open order for [symbol]. Safety fallback when a single
  /// cancel by id can't be relied on.
  Future<Result<void, Object>> cancelAll(String symbol);
}
