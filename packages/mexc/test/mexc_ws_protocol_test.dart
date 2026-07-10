import 'dart:convert';

import 'package:mexc/mexc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  const protocol = MexcWsProtocol();

  group('MexcWsProtocol subscribe messages', () {
    test('ticker topic maps to sub.ticker with the symbol', () {
      final msg = protocol.subscribeMessage('ticker.BTC_USDT');
      expect(msg['method'], 'sub.ticker');
      expect((msg['param']! as Map)['symbol'], 'BTC_USDT');
    });

    test('private topics map to a personal.filter for asset + position', () {
      final msg = protocol.subscribeMessage('position');
      expect(msg['method'], 'personal.filter');
      final filters = (msg['param']! as Map)['filters']! as List;
      expect(filters, [
        {'filter': 'asset'},
        {'filter': 'position'},
      ]);
    });
  });

  group('MexcWsProtocol.decodeFrame', () {
    test('pong channel is a heartbeat', () {
      expect(
        protocol.decodeFrame(jsonEncode({'channel': 'pong', 'data': 1})),
        isA<WsHeartbeat>(),
      );
    });

    test('rs.login success/failure map to auth frames', () {
      expect(
        protocol.decodeFrame(
            jsonEncode({'channel': 'rs.login', 'data': 'success'})),
        isA<WsAuthSuccess>(),
      );
      expect(
        protocol.decodeFrame(jsonEncode({'channel': 'rs.error', 'data': 'x'})),
        isA<WsAuthFailure>(),
      );
    });

    test('push.ticker routes to the per-symbol topic', () {
      final frame = protocol.decodeFrame(jsonEncode({
        'channel': 'push.ticker',
        'data': {'symbol': 'ETH_USDT', 'fairPrice': 3000},
      }));
      expect(frame, isA<WsData>());
      expect((frame as WsData).topic, 'ticker.ETH_USDT');
    });

    test('personal position push (single object) routes to position', () {
      final frame = protocol.decodeFrame(jsonEncode({
        'channel': 'push.personal.position',
        'data': {'symbol': 'BTC_USDT', 'holdVol': 1},
      }));
      expect(frame, isA<WsData>());
      expect((frame as WsData).topic, 'position');
      expect(frame.items, hasLength(1));
    });

    test('malformed frame is ignored', () {
      expect(protocol.decodeFrame('{bad'), isA<WsIgnored>());
    });
  });

  test('pingMessage uses the ping method', () {
    expect((protocol.pingMessage() as Map)['method'], 'ping');
  });
}
