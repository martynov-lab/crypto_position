import 'dart:convert';

import 'package:bybit/bybit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

/// Feeds a Bybit-shaped frame through the protocol into the service, the way
/// WsManager does on the wire.
void _feed(WsService service, Map<String, Object?> frame) {
  final decoded = const BybitWsProtocol().decodeFrame(jsonEncode(frame));
  if (decoded is WsData) service.route(decoded);
}

Map<String, Object?> _positionFrame({
  String symbol = 'BTCUSDT',
  String side = 'Buy',
  String size = '0.1',
  String entryPrice = '60000',
  String markPrice = '61000',
  String unrealisedPnl = '100',
}) =>
    {
      'topic': 'position',
      'data': [
        {
          'symbol': symbol,
          'side': side,
          'size': size,
          'entryPrice': entryPrice,
          'markPrice': markPrice,
          'unrealisedPnl': unrealisedPnl,
          'leverage': '10',
          'positionIdx': 0,
        },
      ],
    };

Map<String, Object?> _tickerFrame(String symbol, {String? markPrice}) => {
      'topic': 'tickers.$symbol',
      'data': {
        'symbol': symbol,
        'markPrice': ?markPrice,
      },
    };

void main() {
  late WsService privateWsService;
  late WsService publicWsService;
  late TickerSubscriptions tickerSubscriptions;
  late BybitAccountRepository repository;
  late List<Map<String, Object?>> publicSent;

  setUp(() {
    privateWsService = WsService(const BybitWsProtocol());
    publicWsService = WsService(const BybitWsProtocol());
    publicSent = [];
    publicWsService.onConnected(publicSent.add);
    tickerSubscriptions = TickerSubscriptions(publicWsService);
    repository = BybitAccountRepository(
      bybitAccountApi: BybitAccountApi(RestClient(Dio())),
      positionSubscriber: PositionSubscriber(privateWsService),
      tickerSubscriptions: tickerSubscriptions,
    );
  });

  tearDown(() {
    repository.dispose();
    privateWsService.dispose();
    publicWsService.dispose();
  });

  group('BybitAccountRepository.positions', () {
    test('upserts a position from the WS position topic and subscribes '
        'to its ticker', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      final position = repository.positions.value!.single;
      expect(position.symbol, 'BTCUSDT');
      expect(position.avgPrice, 60000);
      expect(position.unrealisedPnl, closeTo(100, 0.001));
      expect(
        publicSent,
        anyElement(equals({
          'op': 'subscribe',
          'args': ['tickers.BTCUSDT'],
        })),
      );
    });

    test('recomputes PnL on ticker ticks for Buy and Sell', () async {
      _feed(privateWsService, _positionFrame());
      _feed(
        privateWsService,
        _positionFrame(
          symbol: 'ETHUSDT',
          side: 'Sell',
          size: '2',
          entryPrice: '3000',
          markPrice: '3000',
          unrealisedPnl: '0',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      _feed(publicWsService, _tickerFrame('BTCUSDT', markPrice: '62000'));
      _feed(publicWsService, _tickerFrame('ETHUSDT', markPrice: '2900'));
      await Future<void>.delayed(Duration.zero);

      final positions = repository.positions.value!;
      final btc = positions.singleWhere((p) => p.symbol == 'BTCUSDT');
      final eth = positions.singleWhere((p) => p.symbol == 'ETHUSDT');
      // Buy: 0.1 * (62000 - 60000); Sell: 2 * (3000 - 2900).
      expect(btc.unrealisedPnl, closeTo(200, 0.001));
      expect(eth.unrealisedPnl, closeTo(200, 0.001));
    });

    test('ignores delta ticks without markPrice', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      _feed(publicWsService, _tickerFrame('BTCUSDT'));
      await Future<void>.delayed(Duration.zero);

      final position = repository.positions.value!.single;
      expect(position.markPrice, 61000);
      expect(position.unrealisedPnl, closeTo(100, 0.001));
    });

    test('removes a closed position and unsubscribes its ticker', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);
      publicSent.clear();

      _feed(privateWsService, _positionFrame(size: '0'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.positions.value, isEmpty);
      expect(publicSent, [
        {
          'op': 'unsubscribe',
          'args': ['tickers.BTCUSDT'],
        },
      ]);
    });
  });
}
