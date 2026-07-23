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

  /// The filter set this client explicitly wants, or `null` when it has none
  /// yet and should keep whatever the server is currently running (the
  /// config pushed on connect / echoed by `subscribed`). Set once the caller
  /// calls [reconfigure] (or passes one to the constructor).
  ClientConfig? _explicitConfig;

  /// Max concurrent chart watches per session (server-enforced too).
  static const maxWatches = 3;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  final _lossStopwatch = Stopwatch();
  bool _stopped = true;
  bool _handlingLoss = false;
  bool _disposed = false;
  bool _freshSocket = false;

  /// Active chart watches keyed by instrument pair, so they can be re-sent on a
  /// fresh socket (they survive `subscribe`/reconfigure but not a reconnect).
  final _activeWatches = <String,
      ({
    Instrument instrument,
    int windowMs,
    String? longExchange,
    String? shortExchange,
  })>{};

  final _state = ValueNotifier<WsConnectionState>(
    WsConnectionState.disconnected,
  );
  final _universe = ValueNotifier<List<InstrumentCoverage>>(const []);
  final _effectiveConfig = ValueNotifier<Map<String, Object?>?>(null);
  final _events = StreamController<SignalEvent>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _watchUpdates = StreamController<ScreenerServerMessage>.broadcast();

  ScreenerClient({
    required ScreenerConfig config,
    ClientConfig? clientConfig,
    ScreenerChannelFactory? connect,
    RetryPolicy retryPolicy = const DefaultReconnectPolicy(),
    Duration pingInterval = const Duration(seconds: 25),
    Random? random,
  })  : _config = config,
        _explicitConfig = clientConfig,
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

  /// Chart watch pushes: [ScreenerWatchSnapshot] then [ScreenerSpreadTick]s.
  /// Consumers filter by instrument.
  Stream<ScreenerServerMessage> get watchUpdates => _watchUpdates.stream;

  /// The currently active filter set: this client's explicit override if it
  /// has one, else the server's own config (from the pre-subscribe `config`
  /// push or the `subscribed` ack), with all defaults filled in.
  ClientConfig get clientConfig =>
      _explicitConfig ?? ClientConfig.fromJson(_effectiveConfig.value ?? const {});

  /// Starts a live chart watch for [instrument], pinned to the
  /// [longExchange]/[shortExchange] pair (from the tapped signal: long =
  /// `buy_exchange`, short = `sell_exchange`). Omit the pair to let the server
  /// fix the best pair. Returns `false` (and sends nothing) when the local
  /// [maxWatches] cap is already reached for a new instrument. Re-watching an
  /// instrument already watched refreshes it.
  bool watch(
    Instrument instrument, {
    int windowMs = 900000,
    String? longExchange,
    String? shortExchange,
  }) {
    final key = instrument.pair;
    if (!_activeWatches.containsKey(key) &&
        _activeWatches.length >= maxWatches) {
      return false;
    }
    _activeWatches[key] = (
      instrument: instrument,
      windowMs: windowMs,
      longExchange: longExchange,
      shortExchange: shortExchange,
    );
    if (_state.value == WsConnectionState.connected) {
      _send(_watchMessage(_activeWatches[key]!));
    }
    return true;
  }

  static Map<String, Object?> _watchMessage(
    ({
      Instrument instrument,
      int windowMs,
      String? longExchange,
      String? shortExchange,
    }) watch,
  ) =>
      {
        'type': 'watch',
        'instrument': _instrumentJson(watch.instrument),
        'window_ms': watch.windowMs,
        if (watch.longExchange != null) 'long_exchange': watch.longExchange,
        if (watch.shortExchange != null) 'short_exchange': watch.shortExchange,
      };

  void unwatch(Instrument instrument) {
    if (_activeWatches.remove(instrument.pair) == null) return;
    if (_state.value == WsConnectionState.connected) {
      _send({'type': 'unwatch', 'instrument': _instrumentJson(instrument)});
    }
  }

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

  /// Re-subscribes with a new, explicit filter set. Config is now shared
  /// server-wide (not per-session), so this replaces the server's persisted
  /// config wholesale and every future `subscribe` (incl. after a reconnect)
  /// resends it. The server rebuilds the screening engine and replies with a
  /// fresh `subscribed` ack.
  void reconfigure(ClientConfig config) {
    _explicitConfig = config;
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
    unawaited(_watchUpdates.close());
  }

  void _setState(WsConnectionState value) {
    if (_disposed) return;
    _state.value = value;
  }

  void _openChannel() {
    _handlingLoss = false;
    _freshSocket = true;
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
      case ScreenerConfigPush(:final config):
        // Pushed immediately on connect, before our `subscribe` is acked, so
        // the UI has something to show even before `subscribed` arrives.
        _effectiveConfig.value = config;
      case ScreenerSubscribed(:final effectiveConfig):
        _effectiveConfig.value = effectiveConfig;
        _onConnected();
      case ScreenerUniverse(:final instruments):
        _universe.value = instruments;
      case ScreenerEvent(:final event):
        _events.add(event);
      case ScreenerError(:final message):
        _errors.add(message);
      case ScreenerWatchSnapshot():
      case ScreenerSpreadTick():
        _watchUpdates.add(message);
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
    // Watches survive reconfigure (same socket) but not a reconnect, so only
    // re-send them on a fresh socket's first `subscribed` ack.
    if (_freshSocket) {
      _freshSocket = false;
      for (final watch in _activeWatches.values) {
        _send(_watchMessage(watch));
      }
    }
  }

  static Map<String, Object?> _instrumentJson(Instrument instrument) => {
        'base': instrument.base,
        'quote': instrument.quote,
        'kind': instrument.kind,
      };

  /// An empty token is sent as JSON `null` — the shape the server expects from
  /// an unauthenticated (local) client.
  ///
  /// Omits `config` entirely when this client has no explicit override, so
  /// the server keeps its own persisted (shared) config instead of it being
  /// wholesale-replaced by compiled defaults on every fresh connection.
  void _sendSubscribe() {
    final message = <String, Object?>{
      'type': 'subscribe',
      'token': _config.token.isEmpty ? null : _config.token,
    };
    final explicit = _explicitConfig;
    if (explicit != null) message['config'] = explicit.toJson();
    _send(message);
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
