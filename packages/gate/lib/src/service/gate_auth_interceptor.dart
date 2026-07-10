import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Signs Gate API v4 REST requests.
///
/// Gate signature (all hex): `SIGN = HMAC-SHA512(secret, s)` where `s` is
/// `method\nurlPath\nqueryString\nSHA512(body)\ntimestamp` joined by newlines.
/// `urlPath` includes the `/api/v4` prefix, `queryString` has no leading `?`,
/// `timestamp` is Unix epoch **seconds**, and the body hash is the hex SHA512
/// of the raw body (the hash of the empty string for GET).
class GateAuthInterceptor extends Interceptor {
  final String apiKey;
  final String apiSecret;

  GateAuthInterceptor({required this.apiKey, required this.apiSecret});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final method = options.method.toUpperCase();
    final path = options.uri.path;
    final query = options.uri.query;
    final body = options.data is String ? options.data as String : '';

    final hashedPayload = sha512.convert(utf8.encode(body)).toString();
    final signString = '$method\n$path\n$query\n$hashedPayload\n$timestamp';
    final sign = Hmac(sha512, utf8.encode(apiSecret))
        .convert(utf8.encode(signString))
        .toString();

    options.headers.addAll({
      'KEY': apiKey,
      'Timestamp': timestamp,
      'SIGN': sign,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });

    handler.next(options);
  }
}
