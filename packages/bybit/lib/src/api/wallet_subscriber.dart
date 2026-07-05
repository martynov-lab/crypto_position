import 'package:network/network.dart';

import 'dto/wallet_balance_dto.dart';

/// Subscribes to the Bybit private `wallet` topic.
class WalletSubscriber {
  final _subscriber = WsSubscriber<WalletBalanceDto>(
    'wallet',
    WalletBalanceDto.fromJson,
  );

  Stream<WalletBalanceDto> get stream => _subscriber.stream;

  WalletSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
