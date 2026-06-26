import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/models/wallet_balance.dart';

class BybitWsClient {
  static const _wsUrl = 'wss://stream.bybit.com/v5/private';

  final String apiKey;
  final String apiSecret;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  final _walletController = StreamController<WalletBalance>.broadcast();
  Stream<WalletBalance> get walletStream => _walletController.stream;

  BybitWsClient({required this.apiKey, required this.apiSecret});

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
    _authenticate();

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (error) {
        _scheduleReconnect();
      },
      onDone: _scheduleReconnect,
    );

    _pingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _channel?.sink.add(jsonEncode({'op': 'ping'})),
    );
  }

  void _authenticate() {
    final expires = DateTime.now().millisecondsSinceEpoch + 10000;
    final signature = _sign(expires.toString());
    _channel?.sink.add(
      jsonEncode({
        'op': 'auth',
        'args': [apiKey, expires, signature],
      }),
    );
  }

  String _sign(String expires) {
    final payload = 'GET/realtime$expires';
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;

    if (data['op'] == 'auth' && data['success'] == true) {
      _subscribe();
      return;
    }

    if (data['topic'] == 'wallet') {
      final list = data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        _walletController.add(
          WalletBalance.fromJson(list.first as Map<String, dynamic>),
        );
      }
    }
  }

  void _subscribe() {
    _channel?.sink.add(
      jsonEncode({
        'op': 'subscribe',
        'args': ['wallet'],
      }),
    );
  }

  void _scheduleReconnect() {
    dispose();
    Future.delayed(const Duration(seconds: 5), connect);
  }

  void dispose() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void close() {
    dispose();
    _walletController.close();
  }
}
