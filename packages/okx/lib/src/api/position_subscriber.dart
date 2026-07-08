import 'package:network/network.dart';

import 'dto/position_dto.dart';

/// Subscribes to the OKX private `positions` channel.
///
/// See [AccountSubscriber] for the network-layer generalization this depends
/// on before it drives a live stream.
class PositionSubscriber {
  final _subscriber = WsSubscriber<PositionDto>(
    'positions',
    PositionDto.fromJson,
  );

  Stream<PositionDto> get stream => _subscriber.stream;

  PositionSubscriber(WsService wsService) {
    wsService.addSubscriber(_subscriber);
  }

  void dispose() => _subscriber.dispose();
}
