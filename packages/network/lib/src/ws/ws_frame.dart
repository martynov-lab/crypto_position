/// A decoded incoming WebSocket frame, classified by a [WsProtocol] so the
/// transport core (WsManager/WsService) stays exchange-agnostic.
sealed class WsFrame {
  const WsFrame();
}

/// Authentication/login succeeded; the connection is ready.
class WsAuthSuccess extends WsFrame {
  const WsAuthSuccess();
}

/// Authentication/login failed; the connection should be torn down.
class WsAuthFailure extends WsFrame {
  const WsAuthFailure();
}

/// A heartbeat reply (pong) — no action needed.
class WsHeartbeat extends WsFrame {
  const WsHeartbeat();
}

/// A frame that carries no routable data (subscribe acks, unknown shapes).
class WsIgnored extends WsFrame {
  const WsIgnored();
}

/// A data push for [topic], normalized to a list of JSON objects.
class WsData extends WsFrame {
  final String topic;
  final List<Map<String, Object?>> items;

  const WsData(this.topic, this.items);
}
