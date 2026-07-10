import 'dart:convert';

import 'package:gate/gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  group('GateWsProtocol subscribe messages', () {
    test('ticker subscription is public (no auth) with the contract payload',
        () {
      final protocol = GateWsProtocol();
      final msg = protocol.subscribeMessage('ticker.BTC_USDT');

      expect(msg['channel'], 'futures.tickers');
      expect(msg['event'], 'subscribe');
      expect(msg['payload'], ['BTC_USDT']);
      expect(msg.containsKey('auth'), isFalse);
    });

    test('positions subscription is private, signed, with [userId, "!all"]', () {
      final protocol =
          GateWsProtocol(apiKey: 'k', apiSecret: 's', userId: 20011);
      final msg = protocol.subscribeMessage('positions');

      expect(msg['channel'], 'futures.positions');
      expect(msg['payload'], ['20011', '!all']);
      final auth = msg['auth']! as Map<String, Object?>;
      expect(auth['method'], 'api_key');
      expect(auth['KEY'], 'k');
      expect(auth['SIGN'], matches(RegExp(r'^[0-9a-f]{128}$'))); // HMAC-SHA512
    });

    test('without credentials the positions sub carries no auth block', () {
      final protocol = GateWsProtocol();
      final msg = protocol.subscribeMessage('positions');
      expect(msg.containsKey('auth'), isFalse);
    });
  });

  group('GateWsProtocol.decodeFrame', () {
    final protocol = GateWsProtocol();

    test('futures.pong is a heartbeat', () {
      expect(
        protocol.decodeFrame(jsonEncode({'channel': 'futures.pong'})),
        isA<WsHeartbeat>(),
      );
    });

    test('subscribe ack (including errors) is ignored, not a disconnect', () {
      final frame = protocol.decodeFrame(jsonEncode({
        'channel': 'futures.positions',
        'event': 'subscribe',
        'error': {'code': 2, 'message': 'unauthorized'},
      }));
      expect(frame, isA<WsIgnored>());
    });

    test('position update routes to the positions topic', () {
      final frame = protocol.decodeFrame(jsonEncode({
        'channel': 'futures.positions',
        'event': 'update',
        'result': [
          {'contract': 'BTC_USDT', 'size': 1},
        ],
      }));
      expect(frame, isA<WsData>());
      expect((frame as WsData).topic, 'positions');
    });

    test('ticker update routes to the per-contract topic', () {
      final frame = protocol.decodeFrame(jsonEncode({
        'channel': 'futures.tickers',
        'event': 'update',
        'result': [
          {'contract': 'ETH_USDT', 'mark_price': '3000'},
        ],
      }));
      expect(frame, isA<WsData>());
      expect((frame as WsData).topic, 'ticker.ETH_USDT');
    });

    test('malformed frame is ignored', () {
      expect(protocol.decodeFrame('{bad'), isA<WsIgnored>());
    });
  });

  test('pingMessage targets the futures.ping channel', () {
    final protocol = GateWsProtocol();
    final ping = protocol.pingMessage() as Map<String, Object?>;
    expect(ping['channel'], 'futures.ping');
  });
}
