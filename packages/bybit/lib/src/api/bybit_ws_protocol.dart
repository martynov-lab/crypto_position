import 'dart:convert';

import 'package:network/network.dart';

/// Bybit v5 WebSocket wire protocol.
///
/// Topics are plain strings (`wallet`, `position`, `tickers.BTCUSDT`).
/// Subscribe/unsubscribe use `{op, args:[topic]}`; heartbeats are JSON
/// `{op:ping}`/`{op:pong}`; auth acks arrive as `{op:auth, success}`.
class BybitWsProtocol implements WsProtocol {
  const BybitWsProtocol();

  @override
  Map<String, Object?> subscribeMessage(String topic) => {
        'op': 'subscribe',
        'args': [topic],
      };

  @override
  Map<String, Object?> unsubscribeMessage(String topic) => {
        'op': 'unsubscribe',
        'args': [topic],
      };

  @override
  Object pingMessage() => {'op': 'ping'};

  @override
  WsFrame decodeFrame(String raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const WsIgnored();
    }

    if (message['op'] == 'auth') {
      return message['success'] == true
          ? const WsAuthSuccess()
          : const WsAuthFailure();
    }
    if (message['op'] == 'pong' || message['ret_msg'] == 'pong') {
      return const WsHeartbeat();
    }

    final topic = message['topic'];
    if (topic is String) {
      // `data` is a list on private topics but a single object on public
      // ticker topics, so both shapes are accepted.
      final data = message['data'];
      final items = switch (data) {
        final List<Object?> list => [
            for (final e in list)
              if (e is Map) e.cast<String, Object?>(),
          ],
        final Map<Object?, Object?> map => [map.cast<String, Object?>()],
        _ => const <Map<String, Object?>>[],
      };
      return WsData(topic, items);
    }
    return const WsIgnored();
  }
}
