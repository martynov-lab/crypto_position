import 'package:network/network.dart';

import 'dto/mark_price_dto.dart';

/// Per-instrument `mark-price` subscriptions on the public stream, added and
/// removed as positions open and close (the OKX analog of Bybit's per-symbol
/// ticker subscriptions).
///
/// See [AccountSubscriber] for the network-layer generalization this depends
/// on before it drives a live stream.
class MarkPriceSubscriptions {
  final WsService _wsService;
  final _subscribers = <String, WsSubscriber<MarkPriceDto>>{};

  MarkPriceSubscriptions(this._wsService);

  Stream<MarkPriceDto> subscribe(String instId) {
    final existing = _subscribers[instId];
    if (existing != null) return existing.stream;

    final subscriber = WsSubscriber<MarkPriceDto>(
      'mark-price.$instId',
      MarkPriceDto.fromJson,
    );
    _subscribers[instId] = subscriber;
    _wsService.addSubscriber(subscriber);
    return subscriber.stream;
  }

  void unsubscribe(String instId) {
    final subscriber = _subscribers.remove(instId);
    if (subscriber != null) _wsService.removeSubscriber(subscriber);
  }

  void dispose() {
    for (final subscriber in _subscribers.values) {
      _wsService.removeSubscriber(subscriber);
    }
    _subscribers.clear();
  }
}
