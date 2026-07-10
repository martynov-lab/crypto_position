import 'package:network/network.dart';

import 'dto/position_dto.dart';

/// Subscribes to the MEXC private `position` channel.
class PositionSubscriber {
  final _subscriber = WsSubscriber<PositionDto>(
    'position',
    PositionDto.fromJson,
  );

  Stream<PositionDto> get stream => _subscriber.stream;

  PositionSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
