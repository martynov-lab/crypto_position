import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// Gate v4 USDT-futures order placement. Trading counterpart of
/// [GateAccountApi]; shares the same signed [RestClient].
///
/// Gate sizes orders in whole contracts with a signed integer ([positive] =
/// buy/long, negative = sell/short), so [placeLimitOrder]'s `qty` is a contract
/// count. Gate reports errors via non-2xx HTTP status, which [RestClient]
/// already surfaces as an error `Result` — there is no success envelope.
///
/// Note: these trade endpoints are not live-validated against Gate; they follow
/// the documented v4 shapes.
class GateTradeExecutor implements TradeExecutor {
  static const _base = '/api/v4/futures/usdt';

  final RestClient _client;

  const GateTradeExecutor(this._client);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async {
    // Gate exposes no per-key permission endpoint; a successful authenticated
    // call confirms the key is valid, and the canary order settles trade rights.
    final response = await _client.get<Map<String, Object?>>('$_base/accounts');
    return response.fold(
      (_) => const Ok(ApiKeyPermissions(canTrade: true)),
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> setLeverage(
    String symbol,
    double leverage,
  ) async {
    final response = await _client.post<Map<String, Object?>>(
      '$_base/positions/$symbol/leverage',
      queryParams: {'leverage': _fmt(leverage)},
    );
    return response.fold((_) => const Ok(null), (error) => Err(error));
  }

  @override
  Future<Result<OrderAck, Object>> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double qty,
    required double price,
    bool postOnly = false,
    bool reduceOnly = false,
  }) async {
    // Gate encodes direction in the sign of the (integer) contract size.
    final signed = side == OrderSide.buy ? qty.abs() : -qty.abs();
    final response = await _client.post<Map<String, Object?>>(
      '$_base/orders',
      body: {
        'contract': symbol,
        'size': signed.round(),
        'price': _fmt(price),
        'tif': postOnly ? 'poc' : 'gtc',
        'reduce_only': reduceOnly,
      },
    );
    return response.fold(
      (data) {
        try {
          return Ok(OrderAck(orderId: '${data['id']}'));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> cancelOrder({
    required String symbol,
    required String orderId,
  }) async {
    final response =
        await _client.delete<Map<String, Object?>>('$_base/orders/$orderId');
    return response.fold((_) => const Ok(null), (error) => Err(error));
  }

  @override
  Future<Result<void, Object>> cancelAll(String symbol) async {
    final response = await _client.delete<List<Object?>>(
      '$_base/orders',
      queryParams: {'contract': symbol},
    );
    return response.fold((_) => const Ok(null), (error) => Err(error));
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(10).replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
