import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  group('WsService', () {
    late WsService service;
    late List<Map<String, Object?>> sent;

    void sender(Map<String, Object?> message) => sent.add(message);

    setUp(() {
      service = WsService();
      sent = [];
    });

    test('routes data elements to the subscriber with a matching topic',
        () async {
      final wallet = WsSubscriber<String>(
        'wallet',
        (json) => json['coin']! as String,
      );
      final position = WsSubscriber<String>(
        'position',
        (json) => json['symbol']! as String,
      );
      service
        ..addSubscriber(wallet)
        ..addSubscriber(position);
      final events = <String>[];
      wallet.stream.listen(events.add);

      service.onMessage({
        'topic': 'wallet',
        'data': [
          {'coin': 'BTC'},
          {'coin': 'ETH'},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, ['BTC', 'ETH']);
    });

    test('ignores frames without topic or with scalar data', () {
      final wallet = WsSubscriber<String>(
        'wallet',
        (json) => json['coin']! as String,
      );
      service.addSubscriber(wallet);

      // None of these should throw or emit.
      service.onMessage({'op': 'pong'});
      service.onMessage({'topic': 'wallet', 'data': 'oops'});
      service.onMessage({'topic': 'wallet'});
    });

    test('routes a single-object data payload (public ticker shape)',
        () async {
      final ticker = WsSubscriber<String>(
        'tickers.BTCUSDT',
        (json) => json['markPrice']! as String,
      );
      service.addSubscriber(ticker);
      final events = <String>[];
      ticker.stream.listen(events.add);

      service.onMessage({
        'topic': 'tickers.BTCUSDT',
        'data': {'markPrice': '65000.5'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, ['65000.5']);
    });

    test('removeSubscriber sends unsubscribe and stops routing', () async {
      final ticker = WsSubscriber<String>(
        'tickers.BTCUSDT',
        (json) => json['markPrice']! as String,
      );
      service.addSubscriber(ticker);
      service.onConnected(sender);
      sent.clear();
      final events = <String>[];
      ticker.stream.listen(events.add);

      service.removeSubscriber(ticker);
      service.onMessage({
        'topic': 'tickers.BTCUSDT',
        'data': {'markPrice': '65000.5'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(sent, [
        {
          'op': 'unsubscribe',
          'args': ['tickers.BTCUSDT'],
        },
      ]);
      expect(events, isEmpty);
    });

    test('queues sends while disconnected and flushes them on connect', () {
      service.send({'op': 'custom', 'value': 1});

      expect(sent, isEmpty);

      service.onConnected(sender);

      expect(sent, [
        {'op': 'custom', 'value': 1},
      ]);
    });

    test('re-sends all subscriptions on every connect', () {
      service
        ..addSubscriber(WsSubscriber<int>('wallet', (_) => 1))
        ..subscribe('position');

      service.onConnected(sender);
      final firstConnect = List.of(sent);

      service.onDisconnected();
      sent.clear();
      service.onConnected(sender);

      final expectedSubscribes = [
        {
          'op': 'subscribe',
          'args': ['wallet'],
        },
        {
          'op': 'subscribe',
          'args': ['position'],
        },
      ];
      expect(firstConnect, expectedSubscribes);
      expect(sent, expectedSubscribes);
    });

    test('subscribe sends immediately when connected and deduplicates topics',
        () {
      service.onConnected(sender);
      sent.clear();

      service.subscribe('wallet');
      service.subscribe('wallet');

      expect(sent, [
        {
          'op': 'subscribe',
          'args': ['wallet'],
        },
      ]);
    });

    test('send goes straight through while connected', () {
      service.onConnected(sender);
      sent.clear();

      service.send({'op': 'ping'});

      expect(sent, [
        {'op': 'ping'},
      ]);
    });
  });
}
