import 'dart:convert';

import 'package:bybit/bybit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void _feed(WsService service, Map<String, Object?> frame) {
  final decoded = const BybitWsProtocol().decodeFrame(jsonEncode(frame));
  if (decoded is WsData) service.route(decoded);
}

Map<String, Object?> _positionFrame({
  String symbol = 'BTCUSDT',
  String side = 'Buy',
  String size = '0.1',
}) =>
    {
      'topic': 'position',
      'data': [
        {
          'symbol': symbol,
          'side': side,
          'size': size,
          'entryPrice': '60000',
          'markPrice': '60000',
          'unrealisedPnl': '0',
          'leverage': '10',
          'positionIdx': 0,
        },
      ],
    };

Map<String, Object?> _tickerFrame(
  String symbol, {
  String? markPrice,
  String? fundingRate,
  String? nextFundingTime,
}) =>
    {
      'topic': 'tickers.$symbol',
      'data': {
        'symbol': symbol,
        'markPrice': ?markPrice,
        'fundingRate': ?fundingRate,
        'nextFundingTime': ?nextFundingTime,
      },
    };

TransactionLogDto _log({
  required String symbol,
  required String type,
  String fee = '',
  String funding = '',
  required int at,
}) =>
    TransactionLogDto(
      symbol: symbol,
      type: type,
      fee: fee,
      funding: funding,
      transactionTime: '$at',
    );

void main() {
  group('TransactionLogAggregator.feesFor', () {
    final since = DateTime.utc(2026, 7, 10);
    final before = since.subtract(const Duration(hours: 1));
    final after = since.add(const Duration(hours: 1));

    test('sums TRADE fees and SETTLEMENT funding for the symbol', () {
      final log = [
        _log(
          symbol: 'BTCUSDT',
          type: 'TRADE',
          fee: '0.55',
          at: after.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'TRADE',
          fee: '0.45',
          at: after.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'SETTLEMENT',
          funding: '-1.25',
          at: after.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'SETTLEMENT',
          funding: '0.25',
          at: after.millisecondsSinceEpoch,
        ),
      ];

      final fees = log.feesFor('BTCUSDT', since);
      expect(fees.commission, closeTo(1.0, 1e-9));
      expect(fees.funding, closeTo(-1.0, 1e-9));
    });

    test('excludes other symbols and entries from a previous position', () {
      final log = [
        _log(
          symbol: 'ETHUSDT',
          type: 'TRADE',
          fee: '9',
          at: after.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'TRADE',
          fee: '9',
          at: before.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'SETTLEMENT',
          funding: '-9',
          at: before.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'TRADE',
          fee: '2',
          at: after.millisecondsSinceEpoch,
        ),
      ];

      final fees = log.feesFor('BTCUSDT', since);
      expect(fees.commission, closeTo(2, 1e-9));
      expect(fees.funding, 0);
    });

    test('ignores unrelated entry types and empty amounts', () {
      final log = [
        _log(
          symbol: 'BTCUSDT',
          type: 'TRANSFER_IN',
          at: after.millisecondsSinceEpoch,
        ),
        _log(
          symbol: 'BTCUSDT',
          type: 'TRADE',
          at: after.millisecondsSinceEpoch,
        ),
      ];

      expect(log.feesFor('BTCUSDT', since), emptyPositionFees);
    });
  });

  group('BybitAccountRepository upcoming funding', () {
    late WsService privateWsService;
    late WsService publicWsService;
    late BybitAccountRepository repository;

    setUp(() {
      privateWsService = WsService(const BybitWsProtocol());
      publicWsService = WsService(const BybitWsProtocol());
      repository = BybitAccountRepository(
        bybitAccountApi: BybitAccountApi(RestClient(Dio())),
        positionSubscriber: PositionSubscriber(privateWsService),
        tickerSubscriptions: TickerSubscriptions(publicWsService),
      );
    });

    tearDown(() {
      repository.dispose();
      privateWsService.dispose();
      publicWsService.dispose();
    });

    test('a long pays and a short receives on a positive rate', () async {
      _feed(privateWsService, _positionFrame());
      _feed(privateWsService, _positionFrame(symbol: 'ETHUSDT', side: 'Sell'));
      await Future<void>.delayed(Duration.zero);

      final nextFunding = DateTime.utc(2026, 7, 15, 8);
      _feed(
        publicWsService,
        _tickerFrame(
          'BTCUSDT',
          markPrice: '60000',
          fundingRate: '0.0001',
          nextFundingTime: '${nextFunding.millisecondsSinceEpoch}',
        ),
      );
      _feed(
        publicWsService,
        _tickerFrame('ETHUSDT', markPrice: '3000', fundingRate: '0.0001'),
      );
      await Future<void>.delayed(Duration.zero);

      final positions = repository.positions.value!;
      final btc = positions.singleWhere((p) => p.symbol == 'BTCUSDT');
      final eth = positions.singleWhere((p) => p.symbol == 'ETHUSDT');

      // Long 0.1 @ 60000 = 6000 notional * 0.0001 = 0.6, paid out.
      expect(btc.upcomingFundingUsd, closeTo(-0.6, 1e-9));
      expect(btc.fundingRate, 0.0001);
      // Mapped through the local zone, like every other timestamp here, so
      // compare the instant rather than the wall clock.
      expect(btc.nextFundingTime!.isAtSameMomentAs(nextFunding), isTrue);
      // Short 0.1 @ 3000 = 300 notional * 0.0001 = 0.03, received.
      expect(eth.upcomingFundingUsd, closeTo(0.03, 1e-9));
    });

    test('a negative rate flips who pays', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      _feed(
        publicWsService,
        _tickerFrame('BTCUSDT', markPrice: '60000', fundingRate: '-0.0001'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.positions.value!.single.upcomingFundingUsd,
        closeTo(0.6, 1e-9),
      );
    });

    test('a tick carrying only funding keeps the mark price and PnL', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      _feed(publicWsService, _tickerFrame('BTCUSDT', markPrice: '62000'));
      _feed(publicWsService, _tickerFrame('BTCUSDT', fundingRate: '0.0001'));
      await Future<void>.delayed(Duration.zero);

      final position = repository.positions.value!.single;
      expect(position.markPrice, 62000);
      expect(position.unrealisedPnl, closeTo(200, 1e-9));
      // 0.1 * 62000 = 6200 notional * 0.0001, still repriced off the latest mark.
      expect(position.upcomingFundingUsd, closeTo(-0.62, 1e-9));
    });

    test('a later position frame keeps the funding from the ticker', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      _feed(
        publicWsService,
        _tickerFrame('BTCUSDT', markPrice: '60000', fundingRate: '0.0001'),
      );
      await Future<void>.delayed(Duration.zero);

      // The position topic carries no funding; resizing must not blank the row.
      _feed(privateWsService, _positionFrame(size: '0.2'));
      await Future<void>.delayed(Duration.zero);

      final position = repository.positions.value!.single;
      expect(position.size, 0.2);
      expect(position.fundingRate, 0.0001);
      // Repriced onto the new size: 0.2 * 60000 = 12000 notional * 0.0001.
      expect(position.upcomingFundingUsd, closeTo(-1.2, 1e-9));
    });

    test('funding stays unknown until a rate arrives', () async {
      _feed(privateWsService, _positionFrame());
      await Future<void>.delayed(Duration.zero);

      _feed(publicWsService, _tickerFrame('BTCUSDT', markPrice: '62000'));
      await Future<void>.delayed(Duration.zero);

      final position = repository.positions.value!.single;
      expect(position.fundingRate, isNull);
      expect(position.upcomingFundingUsd, isNull);
    });
  });
}
