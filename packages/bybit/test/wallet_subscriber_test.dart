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

Map<String, Object?> _walletFrame() => {
      'topic': 'wallet',
      'data': [
        {
          'accountType': 'UNIFIED',
          'totalEquity': '10.5',
          'totalWalletBalance': '9.5',
          'coin': [
            {
              'coin': 'USDT',
              'equity': '9.5',
              'walletBalance': '9.5',
              'usdValue': '9.5',
              'unrealisedPnl': '0.25',
            },
          ],
        },
      ],
    };

void main() {
  group('WalletSubscriber', () {
    test('registers on WsService and emits parsed DTOs for wallet frames',
        () async {
      final wsService = WsService(const BybitWsProtocol());
      final subscriber = WalletSubscriber(wsService);
      final events = <WalletBalanceDto>[];
      subscriber.stream.listen(events.add);

      _feed(wsService, _walletFrame());
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.totalEquity, '10.5');
      expect(events.single.coins.single.coin, 'USDT');
      subscriber.dispose();
    });

    test('subscribes to the wallet topic on connect', () {
      final wsService = WsService(const BybitWsProtocol());
      WalletSubscriber(wsService);
      final sent = <Map<String, Object?>>[];

      wsService.onConnected(sent.add);

      expect(
        sent,
        anyElement(equals({
          'op': 'subscribe',
          'args': ['wallet'],
        })),
      );
    });
  });

  group('BybitAccountRepository.balance', () {
    test('updates the balance notifier from wallet frames', () async {
      final wsService = WsService(const BybitWsProtocol());
      final subscriber = WalletSubscriber(wsService);
      final repository = BybitAccountRepository(
        bybitAccountApi: BybitAccountApi(RestClient(Dio())),
        walletSubscriber: subscriber,
      );

      expect(repository.balance.value, isNull);

      _feed(wsService, _walletFrame());
      await Future<void>.delayed(Duration.zero);

      final wallet = repository.balance.value;
      expect(wallet, isNotNull);
      expect(wallet!.totalEquity, 10.5);
      expect(wallet.coins.single.unrealisedPnl, 0.25);
      repository.dispose();
      subscriber.dispose();
    });

    test('stays null without a subscriber', () async {
      final repository = BybitAccountRepository(
        bybitAccountApi: BybitAccountApi(RestClient(Dio())),
      );

      expect(repository.balance.value, isNull);
      repository.dispose();
    });
  });
}
