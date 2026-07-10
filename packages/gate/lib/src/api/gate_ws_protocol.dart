import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:network/network.dart';

/// Gate.io v4 futures WebSocket wire protocol.
///
/// Unlike the login-on-connect exchanges, Gate authenticates **per
/// subscription**: each private subscribe message carries an `auth` block
/// (`HMAC-SHA512(secret, "channel=..&event=..&time=..")`). The connection is
/// therefore treated as authenticated as soon as it opens (no
/// `authMessageFactory`); public and private channels share one connection.
///
/// Internal topics: `positions` (private) and `ticker.<contract>` (public).
/// [userId] must be set (from the REST account) before subscribing to
/// positions — Gate requires it in the payload.
class GateWsProtocol implements WsProtocol {
  final String? apiKey;
  final String? apiSecret;
  int? userId;

  GateWsProtocol({this.apiKey, this.apiSecret, this.userId});

  bool get _canSign => apiKey != null && apiSecret != null;

  @override
  Map<String, Object?> subscribeMessage(String topic) =>
      _message('subscribe', topic);

  @override
  Map<String, Object?> unsubscribeMessage(String topic) =>
      _message('unsubscribe', topic);

  @override
  Object pingMessage() => {
        'time': _nowSeconds(),
        'channel': 'futures.ping',
      };

  @override
  WsFrame decodeFrame(String raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const WsIgnored();
    }

    final channel = message['channel'];
    if (channel == 'futures.pong') return const WsHeartbeat();

    // Subscribe/unsubscribe acks (including single-channel auth errors) carry
    // no routable data; don't tear down the shared connection over them.
    if (message['event'] != 'update') return const WsIgnored();

    final result = message['result'];
    final items = result is List
        ? [
            for (final e in result)
              if (e is Map) e.cast<String, Object?>(),
          ]
        : const <Map<String, Object?>>[];
    if (items.isEmpty) return const WsIgnored();

    if (channel == 'futures.positions') return WsData('positions', items);
    if (channel == 'futures.tickers') {
      // Per-contract subscriptions: route by the first item's contract. A tick
      // batching several contracts would only deliver the first (a documented
      // limitation until this stream is exercised live).
      final contract = items.first['contract'];
      if (contract is String) {
        return WsData('ticker.$contract', [items.first]);
      }
    }
    return const WsIgnored();
  }

  Map<String, Object?> _message(String event, String topic) {
    final time = _nowSeconds();
    final (channel, payload, private) = _route(topic);
    final message = <String, Object?>{
      'time': time,
      'channel': channel,
      'event': event,
      'payload': payload,
    };
    if (private && _canSign) {
      message['auth'] = _auth(channel, event, time);
    }
    return message;
  }

  /// Maps an internal topic to (channel, payload, isPrivate).
  (String, List<String>, bool) _route(String topic) {
    if (topic.startsWith('ticker.')) {
      return ('futures.tickers', [topic.substring('ticker.'.length)], false);
    }
    // Positions: [userId, "!all"] streams every contract for the user.
    return ('futures.positions', [userId?.toString() ?? '', '!all'], true);
  }

  Map<String, Object?> _auth(String channel, String event, int time) {
    final payload = 'channel=$channel&event=$event&time=$time';
    final sign = Hmac(sha512, utf8.encode(apiSecret!))
        .convert(utf8.encode(payload))
        .toString();
    return {'method': 'api_key', 'KEY': apiKey, 'SIGN': sign};
  }

  static int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
