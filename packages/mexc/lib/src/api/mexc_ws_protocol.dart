import 'dart:convert';

import 'package:network/network.dart';

/// MEXC contract WebSocket wire protocol.
///
/// Login is a connect-time op ([mexcWsLoginMessage], sent via the manager's
/// `authMessageFactory`); after it succeeds MEXC pushes personal channels
/// automatically. Internal topics: `position`/`asset` (private) and
/// `ticker.<symbol>` (public). Heartbeat is `{"method":"ping"}` /
/// `{"channel":"pong"}`.
class MexcWsProtocol implements WsProtocol {
  const MexcWsProtocol();

  @override
  Map<String, Object?> subscribeMessage(String topic) {
    if (topic.startsWith('ticker.')) {
      return {
        'method': 'sub.ticker',
        'param': {'symbol': topic.substring('ticker.'.length)},
      };
    }
    // Private data pushes automatically after login; a personal.filter narrows
    // it to the channels we route. Both private subscribers send the same
    // (idempotent) filter.
    return const {
      'method': 'personal.filter',
      'param': {
        'filters': [
          {'filter': 'asset'},
          {'filter': 'position'},
        ],
      },
    };
  }

  @override
  Map<String, Object?> unsubscribeMessage(String topic) {
    if (topic.startsWith('ticker.')) {
      return {
        'method': 'unsub.ticker',
        'param': {'symbol': topic.substring('ticker.'.length)},
      };
    }
    return const {'method': 'personal.filter', 'param': {'filters': []}};
  }

  @override
  Object pingMessage() => const {'method': 'ping'};

  @override
  WsFrame decodeFrame(String raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const WsIgnored();
    }

    final channel = message['channel'];
    if (channel == 'pong') return const WsHeartbeat();
    if (channel == 'rs.login') {
      return message['data'] == 'success'
          ? const WsAuthSuccess()
          : const WsAuthFailure();
    }
    // A login error arrives as `rs.error`; treat it as an auth failure so the
    // manager reconnects (public subscribe acks use `rs.sub.*`, ignored below).
    if (channel == 'rs.error') return const WsAuthFailure();

    if (channel == 'push.ticker') {
      final data = message['data'];
      if (data is Map) {
        final symbol = data['symbol'];
        if (symbol is String) {
          return WsData('ticker.$symbol', [data.cast<String, Object?>()]);
        }
      }
      return const WsIgnored();
    }
    if (channel == 'push.personal.position') {
      return WsData('position', _items(message['data']));
    }
    if (channel == 'push.personal.asset') {
      return WsData('asset', _items(message['data']));
    }
    return const WsIgnored();
  }

  /// MEXC personal pushes carry either a single object or a list; normalize.
  static List<Map<String, Object?>> _items(Object? data) {
    if (data is List) {
      return [
        for (final e in data)
          if (e is Map) e.cast<String, Object?>(),
      ];
    }
    if (data is Map) return [data.cast<String, Object?>()];
    return const [];
  }
}
