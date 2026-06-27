import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../dto/wallet_balance_dto.dart';

class BybitWsClient {
  final WebSocketChannel _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  final _walletController = StreamController<WalletBalanceDto>.broadcast();
  Stream<WalletBalanceDto> get walletStream => _walletController.stream;

  BybitWsClient(this._channel);

  void listen() {
    _subscription = _channel.stream.listen(
      _onMessage,
      onError: (error) => _walletController.addError(error),
    );

    _pingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _channel.sink.add(jsonEncode({'op': 'ping'})),
    );
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
          WalletBalanceDto.fromJson(list.first as Map<String, dynamic>),
        );
      }
    }
  }

  void _subscribe() {
    _channel.sink.add(jsonEncode({
      'op': 'subscribe',
      'args': ['wallet'],
    }));
  }

  void dispose() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel.sink.close();
  }

  void close() {
    dispose();
    _walletController.close();
  }
}
