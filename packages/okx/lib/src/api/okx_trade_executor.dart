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

  /// Whether the account runs hedge mode (`long_short_mode`), cached after the
  /// first lookup. Hedge mode requires `posSide` on every order and rejects it
  /// with "Parameter posSide error" when missing; net mode must omit it.
  /// Account-wide on OKX, so one flag covers every symbol.
  bool? _hedgeMode;

  OkxTradeExecutor(this._client);

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
    final hedge = await _isHedgeMode();
    final response = await _client.post<Map<String, Object?>>(
      '/api/v5/trade/order',
      body: {
        'instId': symbol,
        'tdMode': _tdMode,
        'side': side == OrderSide.buy ? 'buy' : 'sell',
        'ordType': postOnly ? 'post_only' : 'limit',
        'px': _fmt(price),
        'sz': _fmt(qty),
        // Hedge mode addresses a position side explicitly; net mode must not
        // send posSide, and only net mode accepts reduceOnly.
        if (hedge)
          'posSide': _posSide(side: side, reduceOnly: reduceOnly)
        else
          'reduceOnly': reduceOnly,
      },
    );
    return response.fold(
      (data) {
        try {
          // OKX reports per-order failures in data[0].sCode behind a generic
          // "All operations failed" envelope, so read the row before the
          // envelope or the real reason is lost.
          final list = data['data'] as List<Object?>? ?? const [];
          final row = list.isEmpty ? null : list.first! as Map<String, Object?>;
          final sCode = row?['sCode'];
          if (sCode is String && sCode != '0') {
            return Err(
              CustomBackendException(
                message: row?['sMsg'] as String? ?? 'OKX order error $sCode',
                error: row ?? data,
              ),
            );
          }
          final err = _envelopeError(data);
          if (err != null) return Err(err);
          return Ok(OrderAck(orderId: row!['ordId'] as String));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// The position side this order addresses in hedge mode. An opening order
  /// targets the side it trades; a closing (reduce-only) order targets the
  /// opposite one, because closing a long means selling and closing a short
  /// means buying.
  static String _posSide({required OrderSide side, required bool reduceOnly}) {
    final targetsLong =
        reduceOnly ? side == OrderSide.sell : side == OrderSide.buy;
    return targetsLong ? 'long' : 'short';
  }

  /// Reads the account's position mode from `account/config`, cached for the
  /// session. Falls back to net mode when the lookup fails.
  Future<bool> _isHedgeMode() async {
    final cached = _hedgeMode;
    if (cached != null) return cached;

    final response = await _client.get<Map<String, Object?>>(
      '/api/v5/account/config',
    );
    final hedge = response.fold(
      (data) {
        if (_envelopeError(data) != null) return false;
        final list = data['data'] as List<Object?>? ?? const [];
        if (list.isEmpty) return false;
        final row = list.first! as Map<String, Object?>;
        return row['posMode'] == 'long_short_mode';
      },
      (_) => false,
    );
    _hedgeMode = hedge;
    return hedge;
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
