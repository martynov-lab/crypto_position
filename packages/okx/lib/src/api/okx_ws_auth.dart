import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds the OKX private-stream login message.
///
/// Signature: Base64 HMAC-SHA256 of `<timestamp>GET/users/self/verify` keyed
/// by the API secret. [timestamp] is Unix epoch seconds and is overridable for
/// tests; it defaults to now.
///
/// OKX replies with `{"event":"login","code":"0"}` on success (not the Bybit
/// `{"op":"auth","success":true}` shape), so the shared [WsManager] must be
/// generalized before this message drives a live connection.
Map<String, Object?> okxWsLoginMessage({
  required String apiKey,
  required String apiSecret,
  required String passphrase,
  int? timestamp,
}) {
  final ts =
      (timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final sign = base64.encode(
    Hmac(sha256, utf8.encode(apiSecret))
        .convert(utf8.encode('${ts}GET/users/self/verify'))
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
