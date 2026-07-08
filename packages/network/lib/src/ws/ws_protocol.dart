import 'ws_frame.dart';

/// Encodes/decodes one exchange's WebSocket wire dialect.
///
/// The transport core (WsManager/WsService) knows nothing about a specific
/// exchange: it delegates message building and frame classification here.
/// Each exchange package provides its own implementation (e.g.
/// `BybitWsProtocol`, `OkxWsProtocol`).
abstract interface class WsProtocol {
  /// Message that subscribes to [topic].
  Map<String, Object?> subscribeMessage(String topic);

  /// Message that unsubscribes from [topic].
  Map<String, Object?> unsubscribeMessage(String topic);

  /// Periodic heartbeat payload. A [String] is sent raw over the socket; a
  /// [Map] is JSON-encoded first.
  Object pingMessage();

  /// Classifies a raw incoming frame (the string received off the socket).
  WsFrame decodeFrame(String raw);
}
