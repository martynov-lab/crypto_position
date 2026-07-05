import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'default_reconnect_policy.dart';
import 'retry_policy.dart';
import 'ws_connection_state.dart';
import 'ws_service.dart';

typedef WsChannelFactory = WebSocketChannel Function(Uri uri);

/// Owns the WebSocket connection: connect, in-band auth, ping, reconnect.
///
/// The auth message is produced by [authMessageFactory] so protocol-specific
/// signing (e.g. Bybit HMAC) stays outside this package's core.
class WsManager {
  final Uri Function() _getUri;
  final Map<String, Object?> Function() _authMessageFactory;
  final WsService _wsService;
  final RetryPolicy _retryPolicy;
  final WsChannelFactory _connect;
  final Duration _pingInterval;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  final _lossStopwatch = Stopwatch();
  bool _stopped = true;
  bool _handlingLoss = false;

  WsConnectionState _state = WsConnectionState.disconnected;
  final _stateController = StreamController<WsConnectionState>.broadcast();

  WsManager({
    required Uri Function() getUri,
    required Map<String, Object?> Function() authMessageFactory,
    required WsService wsService,
    RetryPolicy retryPolicy = const DefaultReconnectPolicy(),
    WsChannelFactory? connect,
    Duration pingInterval = const Duration(seconds: 20),
  })  : _getUri = getUri,
        _authMessageFactory = authMessageFactory,
        _wsService = wsService,
        _retryPolicy = retryPolicy,
        _connect = connect ?? WebSocketChannel.connect,
        _pingInterval = pingInterval;

  WsConnectionState get state => _state;

  Stream<WsConnectionState> get stateStream => _stateController.stream;

  Future<void> start() async {
    if (!_stopped) return;
    _stopped = false;
    _retryCount = 0;
    _setState(WsConnectionState.connecting);
    _openChannel();
  }

  Future<void> stop() async {
    _stopped = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _wsService.onDisconnected();
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    unawaited(stop().whenComplete(_stateController.close));
  }

  void _openChannel() {
    _handlingLoss = false;
    try {
      final channel = _connect(_getUri());
      _channel = channel;
      _subscription = channel.stream.listen(
        _onData,
        onError: (Object _) => _onChannelLost(),
        onDone: _onChannelLost,
      );
      _send(_authMessageFactory());
    } on Object {
      _onChannelLost();
    }
  }

  void _onData(Object? raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw as String) as Map).cast<String, Object?>();
    } on Object {
      return;
    }

    if (message['op'] == 'auth') {
      if (message['success'] == true) {
        _onAuthenticated();
      } else {
        unawaited(_channel?.sink.close());
        _onChannelLost();
      }
      return;
    }
    if (message['op'] == 'pong' || message['ret_msg'] == 'pong') return;
    if (message.containsKey('topic')) _wsService.onMessage(message);
  }

  void _onAuthenticated() {
    _retryCount = 0;
    _setState(WsConnectionState.connected);
    _pingTimer?.cancel();
    _pingTimer =
        Timer.periodic(_pingInterval, (_) => _send({'op': 'ping'}));
    _wsService.onConnected(_send);
  }

  void _send(Map<String, Object?> message) =>
      _channel?.sink.add(jsonEncode(message));

  void _onChannelLost() {
    if (_stopped || _handlingLoss) return;
    _handlingLoss = true;
    _pingTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel = null;
    _wsService.onDisconnected();

    if (_retryCount == 0) {
      _lossStopwatch
        ..reset()
        ..start();
    }
    final delay = _retryPolicy.nextRetryDelay(
      RetryContext(
        retryCount: _retryCount,
        elapsed: _lossStopwatch.elapsed,
      ),
    );
    if (delay == null) {
      _stopped = true;
      _setState(WsConnectionState.disconnected);
      return;
    }
    _retryCount++;
    _setState(WsConnectionState.reconnecting);
    _retryTimer = Timer(delay, _openChannel);
  }

  void _setState(WsConnectionState value) {
    if (_state == value) return;
    _state = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }
}
