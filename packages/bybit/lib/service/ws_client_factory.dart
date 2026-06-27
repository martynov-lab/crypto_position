import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'bybit_config.dart';

class WsClientFactory {
  WebSocketChannel create({
    required BybitConfig config,
    required String apiKey,
    required String apiSecret,
  }) {
    final channel = WebSocketChannel.connect(Uri.parse(config.baseWsUrl));

    final expires = DateTime.now().millisecondsSinceEpoch + 10000;
    final payload = 'GET/realtime$expires';
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    channel.sink.add(jsonEncode({
      'op': 'auth',
      'args': [apiKey, expires, signature],
    }));

    return channel;
  }
}
