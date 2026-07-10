import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds the Bitget private-stream login message.
///
/// Signature: Base64 HMAC-SHA256 of `<timestamp>GET/user/verify` keyed by the
/// API secret. [timestamp] is Unix epoch **seconds** and is overridable for
/// tests; it defaults to now.
///
/// Bitget replies with `{"event":"login","code":0}` on success.
Map<String, Object?> bitgetWsLoginMessage({
  required String apiKey,
  required String apiSecret,
  required String passphrase,
  int? timestamp,
}) {
  final ts =
      (timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final sign = base64.encode(
    Hmac(sha256, utf8.encode(apiSecret))
        .convert(utf8.encode('${ts}GET/user/verify'))
        .bytes,
  );

  return {
    'op': 'login',
    'args': [
      {
        'apiKey': apiKey,
        'passphrase': passphrase,
        'timestamp': ts,
        'sign': sign,
      },
    ],
  };
}
