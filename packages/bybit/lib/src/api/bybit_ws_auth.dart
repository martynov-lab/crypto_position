import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds the Bybit private-stream auth message.
///
/// Signature: hex HMAC-SHA256 of `GET/realtime<expires>` keyed by the API
/// secret. [expires] is overridable for tests; defaults to now + 60 seconds
/// (a wide margin so auth survives moderate local clock skew).
Map<String, Object?> bybitWsAuthMessage({
  required String apiKey,
  required String apiSecret,
  int? expires,
}) {
  final expiresAt =
      expires ?? DateTime.now().millisecondsSinceEpoch + 60000;
  final signature = Hmac(sha256, utf8.encode(apiSecret))
      .convert(utf8.encode('GET/realtime$expiresAt'))
      .toString();

  return {
    'op': 'auth',
    'args': [apiKey, expiresAt, signature],
  };
}
