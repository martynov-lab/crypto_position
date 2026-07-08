import 'ws_frame.dart';
import 'ws_protocol.dart';
import 'ws_subscriber.dart';

typedef WsSender = void Function(Map<String, Object?> message);

/// Manages subscribers, topic subscriptions and the send queue over a
/// single WebSocket connection driven by WsManager.
///
/// The wire format for subscribe/unsubscribe messages comes from [WsProtocol],
/// so this class stays exchange-agnostic.
class WsService {
  final WsProtocol _protocol;
  final _subscribers = <WsSubscriber<Object?>>[];
  final _topics = <String>{};
  final _sendQueue = <Map<String, Object?>>[];
  WsSender? _sender;

  WsService(this._protocol);

  /// Registers [subscriber] and subscribes to its topic.
  void addSubscriber<T extends Object>(WsSubscriber<T> subscriber) {
    _subscribers.add(subscriber);
    subscribe(subscriber.topic);
  }

  /// Remembers [topic] and subscribes now if connected.
  ///
  /// Topics are re-sent on every connect, so they are not queued.
  void subscribe(String topic) {
    if (_topics.add(topic)) {
      _sender?.call(_protocol.subscribeMessage(topic));
    }
  }

  /// Sends [message] now if connected, otherwise queues it until connect.
  void send(Map<String, Object?> message) {
    final sender = _sender;
    if (sender != null) {
      sender(message);
    } else {
      _sendQueue.add(message);
    }
  }

  /// Called by WsManager after successful authentication.
  void onConnected(WsSender sender) {
    _sender = sender;
    for (final topic in _topics) {
      sender(_protocol.subscribeMessage(topic));
    }
    final queued = List.of(_sendQueue);
    _sendQueue.clear();
    queued.forEach(sender);
  }

  /// Called by WsManager when the connection is lost or stopped.
  void onDisconnected() => _sender = null;

  /// Removes [subscriber] and unsubscribes from its topic.
  void removeSubscriber(WsSubscriber<Object?> subscriber) {
    _subscribers.remove(subscriber);
    if (_topics.remove(subscriber.topic)) {
      _sender?.call(_protocol.unsubscribeMessage(subscriber.topic));
    }
    subscriber.dispose();
  }

  /// Routes a decoded data frame to subscribers by topic.
  void route(WsData frame) {
    for (final subscriber in _subscribers) {
      if (subscriber.topic != frame.topic) continue;
      for (final element in frame.items) {
        subscriber.handle(element);
      }
    }
  }

  void dispose() {
    for (final subscriber in _subscribers) {
      subscriber.dispose();
    }
    _subscribers.clear();
  }
}
