import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// MEXC contract (futures) order placement. Trading counterpart of
/// [MexcAccountApi]; shares the same signed [RestClient].
///
/// MEXC sizes orders in whole contracts (`vol`), so [placeLimitOrder]'s `qty`
/// is a contract count, and encodes direction + open/close in a numeric `side`
/// (1 open-long, 2 close-short, 3 open-short, 4 close-long). Orders use cross
/// margin (`openType` 2).
///
/// Note: MEXC has restricted contract order placement over the API for many
/// keys, and these endpoints are not live-validated; they follow the documented
/// v1 shapes.
class MexcTradeExecutor implements TradeExecutor {
  static const _openTypeCross = 2;

  final RestClient _client;

  const MexcTradeExecutor(this._client);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async {
    // MEXC exposes no per-key permission endpoint; a successful authenticated
    // call confirms the key is valid, and the canary order settles trade rights.
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/private/account/assets',
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        return const Ok(ApiKeyPermissions(canTrade: true));
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> setLeverage(
    String symbol,
    double leverage,
  ) async {
    final response = await _client.post<Map<String, Object?>>(
      '/api/v1/private/position/change_leverage',
      body: {
        'symbol': symbol,
        'leverage': leverage.round(),
        'openType': _openTypeCross,
        // Without an open position MEXC needs a side; best-effort for the long.
        'positionType': 1,
      },
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        return err != null ? Err(err) : const Ok(null);
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> ensureOneWayMode(String symbol) async {
    // Account-wide on MEXC: positionMode 1 = hedge, 2 = one-way.
    final response = await _client.post<Map<String, Object?>>(
      '/api/v1/private/position/change_position_mode',
      body: {'positionMode': 2},
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        return err != null ? Err(err) : const Ok(null);
      },
      (error) => Err(error),
    );
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
    // side: open long=1, close short=2, open short=3, close long=4.
    final int sideCode;
    if (reduceOnly) {
      sideCode = side == OrderSide.buy ? 2 : 4;
    } else {
      sideCode = side == OrderSide.buy ? 1 : 3;
    }
    final response = await _client.post<Map<String, Object?>>(
      '/api/v1/private/order/submit',
      body: {
        'symbol': symbol,
        'price': price,
        'vol': qty.round(),
        'side': sideCode,
        // type: 1 limit, 2 post-only maker.
        'type': postOnly ? 2 : 1,
        'openType': _openTypeCross,
      },
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        return Ok(OrderAck(orderId: '${data['data']}'));
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> cancelOrder({
    required String symbol,
    required String orderId,
  }) async {
    // MEXC cancels by a JSON array of order ids.
    final response = await _client.post<Map<String, Object?>>(
      '/api/v1/private/order/cancel',
      body: [orderId],
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        return err != null ? Err(err) : const Ok(null);
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> cancelAll(String symbol) async {
    final response = await _client.post<Map<String, Object?>>(
      '/api/v1/private/order/cancel_all',
      body: {'symbol': symbol},
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        return err != null ? Err(err) : const Ok(null);
      },
      (error) => Err(error),
    );
  }

  /// MEXC wraps errors in an HTTP 200 envelope; `success == false` is a failure.
  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    if (data['success'] == false) {
      return CustomBackendException(
        message: data['message'] as String? ?? 'MEXC error ${data['code']}',
        error: data,
      );
    }
    return null;
  }
}
