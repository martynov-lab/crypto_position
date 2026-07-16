import 'package:network/network.dart';

import 'dto/funding_rate_dto.dart';

/// Per-instrument `funding-rate` subscriptions on the public stream, added and
/// removed as positions open and close.
///
/// OKX carries the funding rate on its own channel rather than on the mark
/// price, so this sits alongside [MarkPriceSubscriptions] instead of extending
/// it. On Bybit both arrive on the one `tickers` topic.
class FundingRateSubscriptions {
  final WsService _wsService;
  final _subscribers = <String, WsSubscriber<FundingRateDto>>{};

  FundingRateSubscriptions(this._wsService);

  Stream<FundingRateDto> subscribe(String instId) {
    final existing = _subscribers[instId];
    if (existing != null) return existing.stream;

    final subscriber = WsSubscriber<FundingRateDto>(
      'funding-rate.$instId',
      FundingRateDto.fromJson,
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
