import 'dart:convert';

import 'package:network/network.dart';

/// OKX v5 WebSocket wire protocol.
///
/// Topics are encoded as `channel` or `channel.instId` (e.g. `account`,
/// `mark-price.BTC-USDT-SWAP`); this class maps them to/from OKX's `arg`
/// objects. Subscribe/unsubscribe use `{op, args:[{channel, ...}]}`; the
/// heartbeat is the raw string `ping`/`pong`; login acks arrive as
/// `{event:"login", code:"0"}`.
class OkxWsProtocol implements WsProtocol {
  const OkxWsProtocol();

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
      return message['code'] == '0'
          ? const WsAuthSuccess()
          : const WsAuthFailure();
    }
    // `error` on a fresh connection is usually a login failure; subscribe/
    // unsubscribe acks (`event: subscribe`) carry no data.
    if (event == 'error') return const WsAuthFailure();
    if (event != null) return const WsIgnored();

    final arg = message['arg'];
    if (arg is Map) {
      final channel = arg['channel'];
      final instId = arg['instId'];
      if (channel is String) {
        final topic = instId is String ? '$channel.$instId' : channel;
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

  /// Encodes a topic string into an OKX subscription `arg` object.
  static Map<String, Object?> _arg(String topic) {
    final dot = topic.indexOf('.');
    if (dot == -1) {
      // Positions need an instrument-type filter to stream every instrument.
      return topic == 'positions'
          ? {'channel': 'positions', 'instType': 'ANY'}
          : {'channel': topic};
    }
    return {
      'channel': topic.substring(0, dot),
      'instId': topic.substring(dot + 1),
    };
  }
}
