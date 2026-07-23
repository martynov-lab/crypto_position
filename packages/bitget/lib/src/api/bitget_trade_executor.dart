import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// Bitget v2 mix (USDT-futures) order placement. Trading counterpart of
/// [BitgetAccountApi]; shares the same signed [RestClient].
///
/// Bitget sizes orders in the base coin, so [placeLimitOrder]'s `qty` is a base
/// amount. Orders use cross margin.
///
/// Note: these trade endpoints are not live-validated against Bitget; they
/// follow the documented v2 shapes.
class BitgetTradeExecutor implements TradeExecutor {
  static const _productType = 'USDT-FUTURES';
  static const _marginCoin = 'USDT';
  static const _marginMode = 'crossed';

  final RestClient _client;

  const BitgetTradeExecutor(this._client);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async {
    // Bitget exposes no per-key permission endpoint; a successful authenticated
    // call confirms the key is valid, and the canary order settles trade rights.
    final response = await _client.get<Map<String, Object?>>(
      '/api/v2/mix/account/accounts',
      queryParams: const {'productType': _productType},
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
      '/api/v2/mix/account/set-leverage',
      body: {
        'symbol': symbol,
        'productType': _productType,
        'marginCoin': _marginCoin,
        'leverage': _fmt(leverage),
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
    // Account-wide per product type on Bitget; orders here are one-way shaped
    // (no tradeSide), so a hedge-mode account rejects them with 40774.
    final response = await _client.post<Map<String, Object?>>(
      '/api/v2/mix/account/set-position-mode',
      body: {'productType': _productType, 'posMode': 'one_way_mode'},
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
    final response = await _client.post<Map<String, Object?>>(
      '/api/v2/mix/order/place-order',
      body: {
        'symbol': symbol,
        'productType': _productType,
        'marginMode': _marginMode,
        'marginCoin': _marginCoin,
        'size': _fmt(qty),
        'price': _fmt(price),
        'side': side == OrderSide.buy ? 'buy' : 'sell',
        'orderType': 'limit',
        'force': postOnly ? 'post_only' : 'gtc',
        'reduceOnly': reduceOnly ? 'YES' : 'NO',
      },
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        try {
          final payload = data['data'] as Map<String, Object?>;
          return Ok(OrderAck(orderId: payload['orderId'] as String));
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
    final response = await _client.post<Map<String, Object?>>(
      '/api/v2/mix/order/cancel-order',
      body: {
        'symbol': symbol,
        'productType': _productType,
        'orderId': orderId,
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
  Future<Result<void, Object>> cancelAll(String symbol) async {
    final response = await _client.post<Map<String, Object?>>(
      '/api/v2/mix/order/cancel-all-orders',
      body: {
        'symbol': symbol,
        'productType': _productType,
        'marginCoin': _marginCoin,
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

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(10).replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final code = data['code'];
    if (code is String && code != '00000') {
      return CustomBackendException(
        message: data['msg'] as String? ?? 'Bitget error $code',
        error: data,
      );
    }
    return null;
  }
}
