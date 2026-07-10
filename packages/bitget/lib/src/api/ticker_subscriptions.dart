import 'package:network/network.dart';

import 'dto/ticker_dto.dart';

/// Per-instrument `ticker` subscriptions on the public stream, added and
/// removed as positions open and close. The mark price from each tick drives
/// live PnL (the Bitget analog of Bybit's per-symbol ticker subscriptions).
class TickerSubscriptions {
  final WsService _wsService;
  final _subscribers = <String, WsSubscriber<TickerDto>>{};

  TickerSubscriptions(this._wsService);

  Stream<TickerDto> subscribe(String symbol) {
    final existing = _subscribers[symbol];
    if (existing != null) return existing.stream;

    final subscriber = WsSubscriber<TickerDto>(
      'ticker.$symbol',
      TickerDto.fromJson,
    );
    _subscribers[symbol] = subscriber;
    _wsService.addSubscriber(subscriber);
    return subscriber.stream;
  }

  void unsubscribe(String symbol) {
    final subscriber = _subscribers.remove(symbol);
    if (subscriber != null) _wsService.removeSubscriber(subscriber);
  }

  void dispose() {
    for (final subscriber in _subscribers.values) {
      _wsService.removeSubscriber(subscriber);
    }
    _subscribers.clear();
  }
}
