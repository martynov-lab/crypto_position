import 'package:network/network.dart';

import 'dto/balance_dto.dart';

/// Subscribes to the Bitget private `account` channel.
class AccountSubscriber {
  final _subscriber = WsSubscriber<BitgetAccountDto>(
    'account',
    BitgetAccountDto.fromJson,
  );

  Stream<BitgetAccountDto> get stream => _subscriber.stream;

  AccountSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
