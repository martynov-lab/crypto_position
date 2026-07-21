import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Bybit-shaped protocol used to drive the exchange-agnostic WsManager.
class _TestProtocol implements WsProtocol {
  const _TestProtocol();

  @override
  Map<String, Object?> subscribeMessage(String topic) => {
        'op': 'subscribe',
        'args': [topic],
      };

  @override
  Map<String, Object?> unsubscribeMessage(String topic) => {
        'op': 'unsubscribe',
        'args': [topic],
      };

  @override
  Object pingMessage() => {'op': 'ping'};

  @override
  WsFrame decodeFrame(String raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const WsIgnored();
    }
    if (message['op'] == 'auth') {
      return message['success'] == true
          ? const WsAuthSuccess()
          : const WsAuthFailure();
    }
    if (message['op'] == 'pong') return const WsHeartbeat();
    final topic = message['topic'];
    if (topic is String) {
      final data = message['data'];
      final items = data is List
          ? [
              for (final e in data)
                if (e is Map) e.cast<String, Object?>(),
            ]
          : const <Map<String, Object?>>[];
      return WsData(topic, items);
    }
    return const WsIgnored();
  }
}

/// Fake channel: captures client sends, lets tests emit server frames.
class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  final sentFrames = <Map<String, Object?>>[];
  bool closed = false;

  late final _FakeWebSocketSink _sink = _FakeWebSocketSink(this);

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  void emit(Map<String, Object?> frame) => incoming.add(jsonEncode(frame));

  void emitAuthSuccess() => emit({'op': 'auth', 'success': true});

  Future<void> dropConnection() async {
    await incoming.close();
  }
}

class _FakeWebSocketSink implements WebSocketSink {
  final FakeWebSocketChannel channel;
  final _done = Completer<void>();

  _FakeWebSocketSink(this.channel);

  @override
  void add(dynamic data) {
    channel.sentFrames
        .add((jsonDecode(data as String) as Map).cast<String, Object?>());
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    channel.closed = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}

/// Retry policy with no delays, giving up after [maxRetries].
class ImmediateRetryPolicy implements RetryPolicy {
  final int maxRetries;

  const ImmediateRetryPolicy({this.maxRetries = 100});

  @override
  Duration? nextRetryDelay(RetryContext context) =>
      context.retryCount < maxRetries ? Duration.zero : null;
}

void main() {
  group('WsManager', () {
    late List<FakeWebSocketChannel> channels;
    late WsService wsService;

    // Dart does not allow getters inside closures; use a local function.
    FakeWebSocketChannel channel() => channels.last;

    WsManager createManager({
      RetryPolicy retryPolicy = const ImmediateRetryPolicy(),
      Duration pingInterval = const Duration(minutes: 1),
      Duration staleTimeout = const Duration(minutes: 1),
    }) {
      channels = [];
      wsService = WsService(const _TestProtocol());
      return WsManager(
        getUri: () => Uri.parse('wss://example.com/v5/private'),
        authMessageFactory: () => {
          'op': 'auth',
          'args': ['key', 1, 'signature'],
        },
        wsService: wsService,
        protocol: const _TestProtocol(),
        retryPolicy: retryPolicy,
        pingInterval: pingInterval,
        staleTimeout: staleTimeout,
        connect: (_) {
          final fake = FakeWebSocketChannel();
          channels.add(fake);
          return fake;
        },
      );
    }

    test('start sends the auth message and connects on auth success',
        () async {
      final manager = createManager();
      final states = <WsConnectionState>[];
      manager.stateStream.listen(states.add);

      await manager.start();
      expect(manager.state, WsConnectionState.connecting);
      expect(channel().sentFrames, [
        {
          'op': 'auth',
          'args': ['key', 1, 'signature'],
        },
      ]);

      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);

      expect(manager.state, WsConnectionState.connected);
      expect(states,
          [WsConnectionState.connecting, WsConnectionState.connected]);
      manager.dispose();
    });

    test('flushes WsService subscriptions after auth', () async {
      final manager = createManager();
      wsService.subscribe('wallet');

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);

      expect(
        channel().sentFrames,
        anyElement(equals({
          'op': 'subscribe',
          'args': ['wallet'],
        })),
      );
      manager.dispose();
    });

    test('routes topic frames to WsService subscribers', () async {
      final manager = createManager();
      final subscriber = WsSubscriber<String>(
        'wallet',
        (json) => json['coin']! as String,
      );
      wsService.addSubscriber(subscriber);
      final events = <String>[];
      subscriber.stream.listen(events.add);

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);
      channel().emit({
        'topic': 'wallet',
        'data': [
          {'coin': 'BTC'},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, ['BTC']);
      manager.dispose();
    });

    test('sends ping frames periodically while connected', () async {
      final manager =
          createManager(pingInterval: const Duration(milliseconds: 20));

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(const Duration(milliseconds: 70));

      final pings =
          channel().sentFrames.where((f) => f['op'] == 'ping').length;
      expect(pings, greaterThanOrEqualTo(2));
      manager.dispose();
    });

    test('reconnects with re-auth after the channel drops', () async {
      final manager = createManager();

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);

      await channel().dropConnection();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(channels, hasLength(2));
      expect(channels.last.sentFrames, [
        {
          'op': 'auth',
          'args': ['key', 1, 'signature'],
        },
      ]);
      channels.last.emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);
      expect(manager.state, WsConnectionState.connected);
      manager.dispose();
    });

    test('rebuilds the connection when the socket goes silent', () async {
      final manager =
          createManager(staleTimeout: const Duration(milliseconds: 30));

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(channels, hasLength(2));
      expect(channels.first.closed, isTrue);
      manager.dispose();
    });

    test('inbound frames keep the silence watchdog from firing', () async {
      final manager =
          createManager(staleTimeout: const Duration(milliseconds: 40));

      await manager.start();
      channel().emitAuthSuccess();
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        channel().emit({'op': 'pong'});
      }

      expect(channels, hasLength(1));
      expect(manager.state, WsConnectionState.connected);
      manager.dispose();
    });

    test('treats auth failure as a connection failure and retries', () async {
      final manager = createManager();

      await manager.start();
      channel().emit({'op': 'auth', 'success': false});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(channels, hasLength(2));
      manager.dispose();
    });

    test('gives up when the retry policy returns null', () async {
      final manager =
          createManager(retryPolicy: const ImmediateRetryPolicy(maxRetries: 0));

      await manager.start();
      await channel().dropConnection();
      await Future<void>.delayed(Duration.zero);

      expect(manager.state, WsConnectionState.disconnected);
      expect(channels, hasLength(1));
      manager.dispose();
    });

    test('stop closes the channel and prevents retries', () async {
      final manager = createManager();

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);

      await manager.stop();

      expect(manager.state, WsConnectionState.disconnected);
      expect(channel().closed, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(channels, hasLength(1));
      manager.dispose();
    });

    test('dispose emits a final disconnected state before closing the stream',
        () async {
      final manager = createManager();
      final states = <WsConnectionState>[];
      manager.stateStream.listen(states.add);

      await manager.start();
      channel().emitAuthSuccess();
      await Future<void>.delayed(Duration.zero);

      manager.dispose();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, WsConnectionState.disconnected);
    });
  });
}
