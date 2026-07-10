import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds the MEXC contract private-stream login message.
///
/// Signature (hex): `HMAC-SHA256(secret, apiKey + reqTime)`. [reqTime] is Unix
/// epoch **milliseconds** and is overridable for tests; it defaults to now.
/// After a successful login MEXC pushes all personal channels automatically.
Map<String, Object?> mexcWsLoginMessage({
  required String apiKey,
  required String apiSecret,
  int? reqTime,
}) {
  final ts = (reqTime ?? DateTime.now().millisecondsSinceEpoch).toString();
  final signature = Hmac(sha256, utf8.encode(apiSecret))
      .convert(utf8.encode('$apiKey$ts'))
      .toString();

  return {
    'method': 'login',
    'param': {
      'apiKey': apiKey,
      'reqTime': ts,
      'signature': signature,
    },
  };
}
