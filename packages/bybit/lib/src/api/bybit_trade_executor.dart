import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// Bybit v5 order placement (`category=linear`). The trading counterpart of
/// [BybitAccountApi]; shares the same signed [RestClient].
class BybitTradeExecutor implements TradeExecutor {
  static const _category = 'linear';

  final RestClient _client;

  /// Whether the account runs hedge mode for a symbol, cached after the first
  /// probe. Hedge mode needs an explicit `positionIdx` on every order; one-way
  /// mode requires it to be 0. Sending the wrong one fails with retCode 10001
  /// ("position idx not match position mode").
  final _hedgeMode = <String, bool>{};

  BybitTradeExecutor(this._client);

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
  Future<Result<void, Object>> ensureOneWayMode(String symbol) async {
    final response = await _client.post<Map<String, Object?>>(
      '/v5/position/switch-mode',
      body: {'category': _category, 'symbol': symbol, 'mode': 0},
    );
    return response.fold(
      (data) {
        final retCode = data['retCode'];
        // 110025: position mode not modified (already one-way) — treat as OK.
        if (retCode != 110025) {
          final err = _envelopeError(data);
          if (err != null) return Err(err);
        }
        _hedgeMode[symbol] = false;
        return const Ok(null);
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
        'positionIdx': await _positionIdx(
          symbol: symbol,
          side: side,
          reduceOnly: reduceOnly,
        ),
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

  /// The `positionIdx` this order must carry.
  ///
  /// One-way mode always uses 0. Hedge mode addresses a specific side: 1 is the
  /// long position, 2 the short. An opening order targets the side it trades;
  /// a reduce-only order targets the *opposite* side, because closing a long
  /// means selling and closing a short means buying.
  Future<int> _positionIdx({
    required String symbol,
    required OrderSide side,
    required bool reduceOnly,
  }) async {
    if (!await _isHedgeMode(symbol)) return 0;
    final targetsLong =
        reduceOnly ? side == OrderSide.sell : side == OrderSide.buy;
    return targetsLong ? 1 : 2;
  }

  /// Detects the symbol's position mode from its position list: hedge mode
  /// reports entries with a non-zero `positionIdx` (both sides exist even when
  /// flat). Cached per symbol; falls back to one-way if the probe fails.
  Future<bool> _isHedgeMode(String symbol) async {
    final cached = _hedgeMode[symbol];
    if (cached != null) return cached;

    final response = await _client.get<Map<String, Object?>>(
      '/v5/position/list',
      queryParams: {'category': _category, 'symbol': symbol},
    );
    final hedge = response.fold(
      (data) {
        if (_envelopeError(data) != null) return false;
        final result = data['result'] as Map<String, Object?>?;
        final list = result?['list'] as List<Object?>? ?? const [];
        return list.any((e) {
          final idx = (e as Map<String, Object?>?)?['positionIdx'];
          return idx is int && idx != 0;
        });
      },
      (_) => false,
    );
    _hedgeMode[symbol] = hedge;
    return hedge;
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
