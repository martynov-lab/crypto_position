import 'package:network/network.dart';

import 'dto/balance_dto.dart';

/// Subscribes to the OKX private `account` channel.
///
/// NOTE: the shared [WsService] currently encodes Bybit's wire format
/// (`{op:subscribe, args:["topic"]}` and `topic`/`data` routing). OKX uses
/// `{op:subscribe, args:[{channel:"account"}]}` with `arg`/`data` routing, so
/// this subscriber only drives a live stream once the network layer is
/// generalized to a protocol-agnostic subscribe/route strategy.
class AccountSubscriber {
  final _subscriber = WsSubscriber<BalanceDto>(
    'account',
    BalanceDto.fromJson,
  );

  Stream<BalanceDto> get stream => _subscriber.stream;

  AccountSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
