import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/client_config.dart';
import '../models/instrument_coverage.dart';
import '../models/signal_event.dart';
import '../screener_config.dart';
import 'screener_server_message.dart';

typedef ScreenerChannelFactory = WebSocketChannel Function(Uri uri);

/// Owns the WebSocket to the screener server: connect, `subscribe` handshake,
/// app-level ping, and reconnect with backoff + jitter.
///
/// The protocol differs from the exchange feeds (a single `subscribe`-with-
/// config handshake, then `universe`/`event` pushes), so this is a dedicated
/// client rather than an exchange [WsProtocol]. It reuses the network layer's
/// [RetryPolicy] and [WsConnectionState].
class ScreenerClient {
  final ScreenerConfig _config;
  final ScreenerChannelFactory _connect;
  final RetryPolicy _retryPolicy;
  final Duration _pingInterval;
  final Random _random;

  ClientConfig _clientConfig;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  final _lossStopwatch = Stopwatch();
  bool _stopped = true;
  bool _handlingLoss = false;
  bool _disposed = false;

  final _state = ValueNotifier<WsConnectionState>(
    WsConnectionState.disconnected,
  );
  final _universe = ValueNotifier<List<InstrumentCoverage>>(const []);
  final _effectiveConfig = ValueNotifier<Map<String, Object?>?>(null);
  final _events = StreamController<SignalEvent>.broadcast();
  final _errors = StreamController<String>.broadcast();

  ScreenerClient({
    required ScreenerConfig config,
    ClientConfig clientConfig = const ClientConfig(),
    ScreenerChannelFactory? connect,
    RetryPolicy retryPolicy = const DefaultReconnectPolicy(),
    Duration pingInterval = const Duration(seconds: 25),
    Random? random,
  })  : _config = config,
        _clientConfig = clientConfig,
        _connect = connect ?? WebSocketChannel.connect,
        _retryPolicy = retryPolicy,
        _pingInterval = pingInterval,
        _random = random ?? Random();

  /// Current connection state (`connected` == handshake acked).
  ValueListenable<WsConnectionState> get state => _state;

  /// The traded-instrument catalog from the latest `universe` push.
  ValueListenable<List<InstrumentCoverage>> get universe => _universe;

  /// The effective config echoed by the latest `subscribed` ack.
  ValueListenable<Map<String, Object?>?> get effectiveConfig => _effectiveConfig;

  /// Fresh arbitrage signals as they arrive.
  Stream<SignalEvent> get events => _events.stream;

  /// Server-reported errors (invalid config, `unauthorized`, ...).
  Stream<String> get errors => _errors.stream;

  ClientConfig get clientConfig => _clientConfig;

  void start() {
    if (!_stopped || _disposed) return;
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
    _setState(WsConnectionState.disconnected);
  }

  /// Re-subscribes with a new filter set. The server rebuilds the session's
  /// screening engine and replies with a fresh `subscribed` ack.
  void reconfigure(ClientConfig config) {
    _clientConfig = config;
    if (_state.value == WsConnectionState.connected) _sendSubscribe();
  }

  void dispose() {
    _disposed = true;
    _stopped = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_channel?.sink.close());
    _channel = null;
    _state.dispose();
    _universe.dispose();
    _effectiveConfig.dispose();
    unawaited(_events.close());
    unawaited(_errors.close());
  }

  void _setState(WsConnectionState value) {
    if (_disposed) return;
    _state.value = value;
  }

  void _openChannel() {
    _handlingLoss = false;
    try {
      final channel = _connect(_config.wsUri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onData,
        onError: (Object _) => _onChannelLost(),
        onDone: _onChannelLost,
      );
      _sendSubscribe();
    } on Object {
      _onChannelLost();
    }
  }

  void _onData(Object? raw) {
    if (raw is! String) return;
    final ScreenerServerMessage message;
    try {
      message = ScreenerServerMessage.decode(raw);
    } on Object {
      return;
    }

    switch (message) {
      case ScreenerSubscribed(:final effectiveConfig):
        _effectiveConfig.value = effectiveConfig;
        _onConnected();
      case ScreenerUniverse(:final instruments):
        _universe.value = instruments;
      case ScreenerEvent(:final event):
        _events.add(event);
      case ScreenerError(:final message):
        _errors.add(message);
      case ScreenerPong():
      case ScreenerUnknown():
        break;
    }
  }

  void _onConnected() {
    _retryCount = 0;
    _setState(WsConnectionState.connected);
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      _pingInterval,
      (_) => _send({'type': 'ping'}),
    );
  }

  void _sendSubscribe() => _send({
        'type': 'subscribe',
        'token': null,
        'config': _clientConfig.toJson(),
      });

  void _send(Map<String, Object?> message) =>
      _channel?.sink.add(jsonEncode(message));

  void _onChannelLost() {
    if (_stopped || _handlingLoss) return;
    _handlingLoss = true;
    _pingTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel = null;

    if (_retryCount == 0) {
      _lossStopwatch
        ..reset()
        ..start();
    }
    final delay = _retryPolicy.nextRetryDelay(
      RetryContext(retryCount: _retryCount, elapsed: _lossStopwatch.elapsed),
    );
    if (delay == null) {
      _stopped = true;
      _setState(WsConnectionState.disconnected);
      return;
    }
    _retryCount++;
    _setState(WsConnectionState.reconnecting);
    _retryTimer = Timer(_withJitter(delay), _openChannel);
  }

  /// Adds up to 30% positive jitter so reconnecting clients don't thundering-
  /// herd the server after a shared outage.
  Duration _withJitter(Duration delay) {
    if (delay == Duration.zero) return delay;
    final jitterMs = _random.nextInt((delay.inMilliseconds * 0.3).ceil() + 1);
    return delay + Duration(milliseconds: jitterMs);
  }
}
