import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// Bybit v5 order placement (`category=linear`). The trading counterpart of
/// [BybitAccountApi]; shares the same signed [RestClient].
class BybitTradeExecutor implements TradeExecutor {
  static const _category = 'linear';

  final RestClient _client;

  const BybitTradeExecutor(this._client);

  @override
  Future<Result<ApiKeyPermissions, Object>> fetchApiPermissions() async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/user/query-api',
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        try {
          final result = data['result'] as Map<String, Object?>;
          final perms = result['permissions'] as Map<String, Object?>? ?? {};
          final groups = <String>[];
          var canTrade = false;
          for (final entry in perms.entries) {
            final rights = (entry.value as List?)?.cast<Object?>() ?? const [];
            for (final r in rights) {
              groups.add('${entry.key}:$r');
            }
            // Any Order/Trade right in a contract/spot group means the key can
            // place orders.
            if (rights.any((r) => r == 'Order' || r == 'Trade')) {
              canTrade = true;
            }
          }
          return Ok(ApiKeyPermissions(canTrade: canTrade, raw: groups));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  @override
  Future<Result<void, Object>> setLeverage(
    String symbol,
    double leverage,
  ) async {
    final lev = _fmt(leverage);
    final response = await _client.post<Map<String, Object?>>(
      '/v5/position/set-leverage',
      body: {
        'category': _category,
        'symbol': symbol,
        'buyLeverage': lev,
        'sellLeverage': lev,
      },
    );
    return response.fold(
      (data) {
        final retCode = data['retCode'];
        // 110043: leverage not modified (already at this value) — treat as OK.
        if (retCode == 110043) return const Ok(null);
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
      '/v5/order/create',
      body: {
        'category': _category,
        'symbol': symbol,
        'side': side == OrderSide.buy ? 'Buy' : 'Sell',
        'orderType': 'Limit',
        'qty': _fmt(qty),
        'price': _fmt(price),
        'timeInForce': postOnly ? 'PostOnly' : 'GTC',
        'reduceOnly': reduceOnly,
      },
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        if (err != null) return Err(err);
        try {
          final result = data['result'] as Map<String, Object?>;
          return Ok(OrderAck(orderId: result['orderId'] as String));
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
      '/v5/order/cancel',
      body: {'category': _category, 'symbol': symbol, 'orderId': orderId},
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
      '/v5/order/cancel-all',
      body: {'category': _category, 'symbol': symbol},
    );
    return response.fold(
      (data) {
        final err = _envelopeError(data);
        return err != null ? Err(err) : const Ok(null);
      },
      (error) => Err(error),
    );
  }

  /// Formats a number for Bybit's string fields without a trailing `.0` or
  /// scientific notation (which Bybit rejects).
  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(10);
    // Trim trailing zeros but keep at least one decimal digit.
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Bybit wraps errors in an HTTP 200 envelope; `retCode != 0` is a failure.
  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final retCode = data['retCode'];
    if (retCode is int && retCode != 0) {
      return CustomBackendException(
        message: data['retMsg'] as String? ?? 'Bybit error $retCode',
        error: data,
      );
    }
    return null;
  }
}
