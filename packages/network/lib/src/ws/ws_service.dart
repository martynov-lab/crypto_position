import 'ws_subscriber.dart';

typedef WsSender = void Function(Map<String, Object?> message);

/// Manages subscribers, topic subscriptions and the send queue over a
/// single WebSocket connection driven by WsManager.
class WsService {
  final _subscribers = <WsSubscriber<Object?>>[];
  final _topics = <String>{};
  final _sendQueue = <Map<String, Object?>>[];
  WsSender? _sender;

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
      _sender?.call(_subscribeMessage(topic));
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
      sender(_subscribeMessage(topic));
    }
    final queued = List.of(_sendQueue);
    _sendQueue.clear();
    queued.forEach(sender);
  }

  /// Called by WsManager when the connection is lost or stopped.
  void onDisconnected() => _sender = null;

  /// Routes an incoming decoded frame to subscribers by topic.
  void onMessage(Map<String, Object?> message) {
    final topic = message['topic'];
    final data = message['data'];
    if (topic is! String || data is! List) return;

    for (final subscriber in _subscribers) {
      if (subscriber.topic != topic) continue;
      for (final element in data) {
        if (element is Map) {
          subscriber.handle(element.cast<String, Object?>());
        }
      }
    }
  }

  void dispose() {
    for (final subscriber in _subscribers) {
      subscriber.dispose();
    }
    _subscribers.clear();
  }

  static Map<String, Object?> _subscribeMessage(String topic) => {
        'op': 'subscribe',
        'args': [topic],
      };
}
