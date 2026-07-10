import 'dart:convert';

import 'package:network/network.dart';

/// Product type every Bitget subscription is scoped to (USDT perpetuals).
const _instType = 'USDT-FUTURES';

/// Bitget v2 WebSocket wire protocol.
///
/// Topics are encoded as `account`, `positions` or `ticker.<symbol>`; this
/// class maps them to/from Bitget's `arg` objects (`{instType, channel, ...}`).
/// Subscribe/unsubscribe use `{op, args:[{...}]}`; the heartbeat is the raw
/// string `ping`/`pong`; login acks arrive as `{event:"login", code:0}`.
class BitgetWsProtocol implements WsProtocol {
  const BitgetWsProtocol();

  @override
  Map<String, Object?> subscribeMessage(String topic) => {
        'op': 'subscribe',
        'args': [_arg(topic)],
      };

  @override
  Map<String, Object?> unsubscribeMessage(String topic) => {
        'op': 'unsubscribe',
        'args': [_arg(topic)],
      };

  @override
  Object pingMessage() => 'ping';

  @override
  WsFrame decodeFrame(String raw) {
    if (raw == 'pong') return const WsHeartbeat();

    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const WsIgnored();
    }

    final event = message['event'];
    if (event == 'login') {
      final code = message['code'];
      return code == '0' || code == 0
          ? const WsAuthSuccess()
          : const WsAuthFailure();
    }
    // `error` on a fresh connection is usually a login failure. Subscribe acks
    // (`event: subscribe`) carry no data.
    if (event == 'error') return const WsAuthFailure();
    if (event != null) return const WsIgnored();

    final arg = message['arg'];
    if (arg is Map) {
      final channel = arg['channel'];
      final instId = arg['instId'];
      if (channel is String) {
        // Only the per-symbol ticker carries a routable instId; account and
        // positions are single channels regardless of any instId filter.
        final topic = channel == 'ticker' && instId is String
            ? 'ticker.$instId'
            : channel;
        final data = message['data'];
        final items = data is List
            ? [
                for (final e in data)
                  if (e is Map) e.cast<String, Object?>(),
              ]
            : const <Map<String, Object?>>[];
        return WsData(topic, items);
      }
    }
    return const WsIgnored();
  }

  /// Encodes a topic string into a Bitget subscription `arg` object.
  static Map<String, Object?> _arg(String topic) {
    final dot = topic.indexOf('.');
    if (dot != -1 && topic.substring(0, dot) == 'ticker') {
      return {
        'instType': _instType,
        'channel': 'ticker',
        'instId': topic.substring(dot + 1),
      };
    }
    // Private channels use a `default` filter to stream every instrument.
    if (topic == 'account') {
      return {'instType': _instType, 'channel': 'account', 'coin': 'default'};
    }
    return {'instType': _instType, 'channel': topic, 'instId': 'default'};
  }
}
