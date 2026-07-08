import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Signs OKX REST requests.
///
/// OKX signature: Base64(HMAC-SHA256(`timestamp + method + requestPath + body`,
/// secret)). [timestamp] is an ISO-8601 UTC instant with milliseconds
/// (e.g. `2020-12-08T09:08:57.715Z`), `requestPath` is everything after the
/// host including the query string, and `body` is the raw request body (empty
/// for GET).
class OkxAuthInterceptor extends Interceptor {
  final String apiKey;
  final String apiSecret;
  final String passphrase;
  final bool demoTrading;

  OkxAuthInterceptor({
    required this.apiKey,
    required this.apiSecret,
    required this.passphrase,
    this.demoTrading = false,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final method = options.method.toUpperCase();

    // Sign the path + query exactly as it goes on the wire.
    final query = options.uri.query;
    final requestPath =
        query.isEmpty ? options.uri.path : '${options.uri.path}?$query';

    final body = options.data is String ? options.data as String : '';

    final payload = '$timestamp$method$requestPath$body';
    final sign = base64.encode(
      Hmac(sha256, utf8.encode(apiSecret)).convert(utf8.encode(payload)).bytes,
    );

    options.headers.addAll({
      'OK-ACCESS-KEY': apiKey,
      'OK-ACCESS-SIGN': sign,
      'OK-ACCESS-TIMESTAMP': timestamp,
      'OK-ACCESS-PASSPHRASE': passphrase,
      if (demoTrading) 'x-simulated-trading': '1',
    });

    handler.next(options);
  }
}
