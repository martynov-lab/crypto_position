import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:screener/screener.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late FakeWebSocketChannel channel;
  late ScreenerClient client;

  setUp(() {
    channel = FakeWebSocketChannel();
    client = ScreenerClient(
      config: const ScreenerConfig(),
      clientConfig: const ClientConfig(minNetSpreadPct: '0.03'),
      connect: (_) => channel,
    );
  });

  tearDown(() => client.dispose());

  // Stream frames are delivered on a later microtask; let the loop turn.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('sends a subscribe handshake on connect', () {
    client.start();
    expect(channel.sent, hasLength(1));
    expect(channel.sent.single['type'], 'subscribe');
    expect(channel.sent.single['token'], isNull);
    expect(
      (channel.sent.single['config'] as Map)['min_net_spread_pct'],
      '0.03',
    );
  });

  test('sends the configured token in the subscribe handshake', () {
    final channel = FakeWebSocketChannel();
    final client = ScreenerClient(
      config: const ScreenerConfig(token: 'secret'),
      connect: (_) => channel,
    );
    addTearDown(client.dispose);
    client.start();
    expect(channel.sent.single['token'], 'secret');
  });

  test(
      'a client with no explicit config omits the config key so the server '
      'keeps its own persisted (shared) settings', () {
    final channel = FakeWebSocketChannel();
    final client = ScreenerClient(
      config: const ScreenerConfig(),
      connect: (_) => channel,
    );
    addTearDown(client.dispose);
    client.start();
    expect(channel.sent.single.containsKey('config'), isFalse);
  });

  test('the config push (pre-subscribe) populates effectiveConfig', () async {
    final channel = FakeWebSocketChannel();
    final client = ScreenerClient(
      config: const ScreenerConfig(),
      connect: (_) => channel,
    );
    addTearDown(client.dispose);
    client.start();
    channel.emit({
      'type': 'config',
      'config': {'quote': 'USDT', 'min_net_spread_pct': '0.02'},
    });
    await flush();
    expect(client.effectiveConfig.value?['min_net_spread_pct'], '0.02');
    // Not yet connected — that only happens once `subscribed` arrives.
    expect(client.state.value, isNot(WsConnectionState.connected));
    // No explicit override: clientConfig reflects the server-pushed values.
    expect(client.clientConfig.minNetSpreadPct, '0.02');
  });

  test('ScreenerConfig uses TLS for a remote host and plain for loopback', () {
    const remote = ScreenerConfig(host: 'arovit-screener.duckdns.org');
    expect(remote.wsUri.toString(), 'wss://arovit-screener.duckdns.org/ws');
    expect(remote.baseRestUrl, 'https://arovit-screener.duckdns.org');

    const local = ScreenerConfig(host: '127.0.0.1:8080');
    expect(local.wsUri.toString(), 'ws://127.0.0.1:8080/ws');
    expect(local.baseRestUrl, 'http://127.0.0.1:8080');
  });

  test('subscribed ack flips state to connected and stores effective config',
      () async {
    client.start();
    channel.emit({
      'type': 'subscribed',
      'config': {'quote': 'USDT', 'exchanges': ['bybit', 'okx']},
    });
    await flush();
    expect(client.state.value, WsConnectionState.connected);
    expect(client.effectiveConfig.value?['quote'], 'USDT');
  });

  test('routes universe and event pushes', () async {
    client.start();
    channel.emit({'type': 'subscribed', 'config': {}});

    final eventFuture = client.events.first;
    channel.emit({
      'type': 'universe',
      'instruments': [
        {'base': 'BTC', 'quote': 'USDT', 'exchanges': ['bybit'], 'coverage': 1},
      ],
    });
    await flush();
    expect(client.universe.value.single.pair, 'BTC/USDT');

    channel.emit({
      'type': 'event',
      'spread': {
        'instrument': {'base': 'ARB', 'quote': 'USDT', 'kind': 'perp'},
        'buy_exchange': 'mexc',
        'sell_exchange': 'kucoin',
        'vwap_buy': '1', 'vwap_sell': '1', 'gross_pct': '0',
        'net_pct': '0.0289', 'executable_notional': '2000',
        'capped_by_depth': false,
      },
      'ts_ms': 1,
    });
    final event = await eventFuture;
    expect(event.instrument.pair, 'ARB/USDT');
    expect(event.spread.netPct, '0.0289');
  });

  test('reconfigure re-sends subscribe with the new config when connected',
      () async {
    client.start();
    channel.emit({'type': 'subscribed', 'config': {}});
    await flush();
    channel.sent.clear();

    client.reconfigure(const ClientConfig(maxNetSpreadPct: '0.10'));
    expect(channel.sent, hasLength(1));
    expect(
      (channel.sent.single['config'] as Map)['max_net_spread_pct'],
      '0.10',
    );
  });

  test('surfaces server errors', () async {
    client.start();
    final errorFuture = client.errors.first;
    channel.emit({'type': 'error', 'message': 'unauthorized'});
    expect(await errorFuture, 'unauthorized');
  });

  test('watch sends a watch message when connected', () async {
    client.start();
    channel.emit({'type': 'subscribed', 'config': {}});
    await flush();
    channel.sent.clear();

    final ok = client.watch(
      const Instrument(base: 'ARB', quote: 'USDT', kind: 'perp'),
      windowMs: 600000,
      longExchange: 'mexc',
      shortExchange: 'kucoin',
    );
    expect(ok, isTrue);
    expect(channel.sent.single['type'], 'watch');
    expect(
      (channel.sent.single['instrument'] as Map)['base'],
      'ARB',
    );
    expect(channel.sent.single['window_ms'], 600000);
    expect(channel.sent.single['long_exchange'], 'mexc');
    expect(channel.sent.single['short_exchange'], 'kucoin');
  });

  test('watch cap rejects a 4th distinct instrument', () {
    client.start();
    Instrument inst(String base) =>
        Instrument(base: base, quote: 'USDT', kind: 'perp');
    expect(client.watch(inst('A')), isTrue);
    expect(client.watch(inst('B')), isTrue);
    expect(client.watch(inst('C')), isTrue);
    expect(client.watch(inst('D')), isFalse);
    // Re-watching an already-watched instrument is allowed (refresh).
    expect(client.watch(inst('A')), isTrue);
  });

  test('SpreadChartController buffers snapshot + ticks and trims to window',
      () async {
    client.start();
    channel.emit({'type': 'subscribed', 'config': {}});
    await flush();

    const instrument = Instrument(base: 'ARB', quote: 'USDT', kind: 'perp');
    final controller =
        SpreadChartController(client, instrument: instrument, windowMs: 5000);
    expect(controller.start(), isTrue);
    expect(channel.sent.any((m) => m['type'] == 'watch'), isTrue);

    void emitTick(int ts, String net) => channel.emit({
          'type': 'spread_tick',
          'instrument': {'base': 'ARB', 'quote': 'USDT', 'kind': 'perp'},
          'point': {'ts_ms': ts, 'net_pct': net},
        });

    channel.emit({
      'type': 'watch_snapshot',
      'instrument': {'base': 'ARB', 'quote': 'USDT', 'kind': 'perp'},
      'resolution_ms': 1000,
      'window_ms': 5000,
      'points': [
        {'ts_ms': 1000, 'net_pct': '0.01'},
        {'ts_ms': 2000, 'net_pct': '0.02'},
      ],
    });
    await flush();
    expect(controller.points.value.map((p) => p.tsMs), [1000, 2000]);

    emitTick(3000, '0.03');
    await flush();
    expect(controller.points.value.length, 3);

    // A far-future tick pushes the window forward and drops stale points.
    emitTick(9000, '0.04');
    await flush();
    expect(controller.points.value.map((p) => p.tsMs), [9000]);

    controller.dispose();
    expect(channel.sent.any((m) => m['type'] == 'unwatch'), isTrue);
  });
}

/// In-memory [WebSocketChannel]: captures client sends, lets tests emit frames.
class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  final sent = <Map<String, Object?>>[];

  late final _FakeSink _sink = _FakeSink(this);

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
}

class _FakeSink implements WebSocketSink {
  final FakeWebSocketChannel channel;
  final _done = Completer<void>();

  _FakeSink(this.channel);

  @override
  void add(dynamic data) => channel.sent
      .add((jsonDecode(data as String) as Map).cast<String, Object?>());

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}
