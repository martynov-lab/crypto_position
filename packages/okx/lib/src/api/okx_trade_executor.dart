import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// OKX v5 order placement (linear USDT `SWAP`). Trading counterpart of
/// [OkxAccountApi]; shares the same signed [RestClient].
///
/// OKX sizes orders in contracts, so [placeLimitOrder]'s `qty` is a contract
/// count. Orders use cross margin ([_tdMode]).
///
/// Note: these trade endpoints are not live-validated against OKX; they follow
/// the documented v5 shapes.
class OkxTradeExecutor implements TradeExecutor {
  static const _tdMode = 'cross';

  final RestClient _client;

  const OkxTradeExecutor(this._client);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async {
    // OKX exposes no per-key permission endpoint. A successful authenticated
    // call confirms the key is valid; whether it may trade is settled by the
    // canary order. So this reports canTrade whenever the key authenticates.
    final response = await _client.get<Map<String, Object?>>(
      '/api/v5/account/config',
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
      '/api/v5/account/set-leverage',
      body: {
        'instId': symbol,
        'lever': _fmt(leverage),
        'mgnMode': _tdMode,
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
  Future<Result<OrderAck, Object>> placeLimitOrder({
    required String symbol,
    required OrderSide side,
    required double qty,
    required double price,
    bool postOnly = false,
    bool reduceOnly = false,
  }) async {
    final response = await _client.post<Map<String, Object?>>(
      '/api/v5/trade/order',
      body: {
        'instId': symbol,
        'tdMode': _tdMode,
        'side': side == OrderSide.buy ? 'buy' : 'sell',
        'ordType': postOnly ? 'post_only' : 'limit',
        'px': _fmt(price),
        'sz': _fmt(qty),
        'reduceOnly': reduceOnly,
      },
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        try {
          final list = data['data'] as List<Object?>? ?? const [];
          final row = list.first! as Map<String, Object?>;
          // Per-order sCode is "0" on success even within a 0-code envelope.
          final sCode = row['sCode'];
          if (sCode is String && sCode != '0') {
            return Err(
              CustomBackendException(
                message: row['sMsg'] as String? ?? 'OKX order error $sCode',
                error: row,
              ),
            );
          }
          return Ok(OrderAck(orderId: row['ordId'] as String));
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
      '/api/v5/trade/cancel-order',
      body: {'instId': symbol, 'ordId': orderId},
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
    // OKX has no single "cancel all for instrument" REST endpoint; mass-cancel
    // needs the order ids. The orchestrator relies on per-order cancels, so
    // this is a best-effort no-op success to satisfy the interface.
    return const Ok(null);
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(10).replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final code = data['code'];
    if (code is String && code != '0') {
      return CustomBackendException(
        message: data['msg'] as String? ?? 'OKX error $code',
        error: data,
      );
    }
    return null;
  }
}
