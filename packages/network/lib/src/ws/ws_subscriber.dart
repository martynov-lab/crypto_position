import 'dart:async';

/// Maps raw WebSocket topic payloads to typed DTO events.
///
/// [mapper] is typically `SomeDto.fromJson`.
class WsSubscriber<T> {
  final String topic;
  final T Function(Map<String, Object?> json) mapper;

  final _controller = StreamController<T>.broadcast();

  WsSubscriber(this.topic, this.mapper);

  Stream<T> get stream => _controller.stream;

  /// Called by WsService with each element of the message `data` list.
  ///
  /// Elements the mapper cannot parse are skipped.
  void handle(Map<String, Object?> json) {
    final T value;
    try {
      value = mapper(json);
    } on Object {
      return;
    }
    _controller.add(value);
  }

  void dispose() => _controller.close();
}
