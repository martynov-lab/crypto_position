import 'dart:convert';

import '../models/instrument_coverage.dart';
import '../models/signal_event.dart';

/// A decoded message pushed by the screener server, tagged by its `type` field.
sealed class ScreenerServerMessage {
  const ScreenerServerMessage();

  /// Decodes a raw WS text frame. Returns [ScreenerUnknown] for shapes we do
  /// not model, and throws only when [raw] is not valid JSON object text.
  factory ScreenerServerMessage.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const ScreenerUnknown();
    final json = decoded.cast<String, Object?>();
    switch (json['type']) {
      case 'subscribed':
        final config = json['config'];
        return ScreenerSubscribed(
          config is Map ? config.cast<String, Object?>() : const {},
        );
      case 'universe':
        final rows = (json['instruments'] as List?) ?? const [];
        return ScreenerUniverse(
          rows
              .whereType<Map>()
              .map((e) => InstrumentCoverage.fromJson(e.cast<String, Object?>()))
              .toList(),
        );
      case 'event':
        return ScreenerEvent(SignalEvent.fromJson(json));
      case 'pong':
        return const ScreenerPong();
      case 'error':
        return ScreenerError(json['message']?.toString() ?? 'unknown error');
      default:
        return const ScreenerUnknown();
    }
  }
}

/// Handshake ack; carries the *effective* config with all defaults filled in.
class ScreenerSubscribed extends ScreenerServerMessage {
  final Map<String, Object?> effectiveConfig;
  const ScreenerSubscribed(this.effectiveConfig);
}

/// The traded-instrument catalog, pushed once after [ScreenerSubscribed].
class ScreenerUniverse extends ScreenerServerMessage {
  final List<InstrumentCoverage> instruments;
  const ScreenerUniverse(this.instruments);
}

/// A fresh arbitrage signal.
class ScreenerEvent extends ScreenerServerMessage {
  final SignalEvent event;
  const ScreenerEvent(this.event);
}

/// Keepalive reply.
class ScreenerPong extends ScreenerServerMessage {
  const ScreenerPong();
}

/// Auth/config error; the server closes the socket on auth failures.
class ScreenerError extends ScreenerServerMessage {
  final String message;
  const ScreenerError(this.message);
}

/// A frame we do not model; ignored.
class ScreenerUnknown extends ScreenerServerMessage {
  const ScreenerUnknown();
}
