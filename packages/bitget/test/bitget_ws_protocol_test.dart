import 'dart:convert';

import 'package:bitget/bitget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  const protocol = BitgetWsProtocol();

  group('BitgetWsProtocol topic <-> arg symmetry', () {
    // A topic must decode back to the same string it was subscribed with, or
    // routing by topic breaks.
    for (final topic in ['account', 'positions', 'ticker.BTCUSDT']) {
      test('round-trips "$topic"', () {
        final arg = (protocol.subscribeMessage(topic)['args']! as List).first
            as Map<String, Object?>;

        final frame = protocol.decodeFrame(
          jsonEncode({
            'arg': arg,
            'data': [<String, Object?>{}],
          }),
        );

        expect(frame, isA<WsData>());
        expect((frame as WsData).topic, topic);
      });
    }

    test('every subscription is scoped to USDT-FUTURES', () {
      final arg = (protocol.subscribeMessage('positions')['args']! as List)
          .first as Map<String, Object?>;
      expect(arg['instType'], 'USDT-FUTURES');
    });
  });

  group('BitgetWsProtocol.decodeFrame', () {
    test('raw pong is a heartbeat (handled before jsonDecode)', () {
      expect(protocol.decodeFrame('pong'), isA<WsHeartbeat>());
    });

    test('login code 0 as int or string is auth success', () {
      expect(
        protocol.decodeFrame(jsonEncode({'event': 'login', 'code': 0})),
        isA<WsAuthSuccess>(),
      );
      expect(
        protocol.decodeFrame(jsonEncode({'event': 'login', 'code': '0'})),
        isA<WsAuthSuccess>(),
      );
    });

    test('login with a non-zero code is auth failure', () {
      expect(
        protocol.decodeFrame(jsonEncode({'event': 'login', 'code': 30005})),
        isA<WsAuthFailure>(),
      );
    });

    test('error event is treated as auth failure', () {
      expect(
        protocol.decodeFrame(jsonEncode({'event': 'error', 'code': 30012})),
        isA<WsAuthFailure>(),
      );
    });

    test('malformed frame is ignored', () {
      expect(protocol.decodeFrame('{not json'), isA<WsIgnored>());
    });
  });

  test('pingMessage is the raw string ping', () {
    expect(protocol.pingMessage(), 'ping');
  });
}
