import 'package:network/network.dart';

import 'dto/ticker_dto.dart';

/// Per-contract `futures.tickers` subscriptions, added and removed as positions
/// open and close. The mark price from each tick drives live PnL.
class TickerSubscriptions {
  final WsService _wsService;
  final _subscribers = <String, WsSubscriber<TickerDto>>{};

  TickerSubscriptions(this._wsService);

  Stream<TickerDto> subscribe(String contract) {
    final existing = _subscribers[contract];
    if (existing != null) return existing.stream;

    final subscriber = WsSubscriber<TickerDto>(
      'ticker.$contract',
      TickerDto.fromJson,
    );
    _subscribers[contract] = subscriber;
    _wsService.addSubscriber(subscriber);
    return subscriber.stream;
  }

  void unsubscribe(String contract) {
    final subscriber = _subscribers.remove(contract);
    if (subscriber != null) _wsService.removeSubscriber(subscriber);
  }

  void dispose() {
    for (final subscriber in _subscribers.values) {
      _wsService.removeSubscriber(subscriber);
    }
    _subscribers.clear();
  }
}
