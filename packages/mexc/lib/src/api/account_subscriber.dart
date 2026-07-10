import 'package:network/network.dart';

import 'dto/balance_dto.dart';

/// Subscribes to the MEXC private `asset` channel (per-currency balance push).
class AccountSubscriber {
  final _subscriber = WsSubscriber<AssetDto>('asset', AssetDto.fromJson);

  Stream<AssetDto> get stream => _subscriber.stream;

  AccountSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
