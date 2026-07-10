import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Signs Bitget v2 REST requests.
///
/// Bitget signature: Base64(HMAC-SHA256(`timestamp + method + requestPath +
/// body`, secret)). [timestamp] is Unix epoch **milliseconds** as a string,
/// `requestPath` is everything after the host including the query string, and
/// `body` is the raw request body (empty for GET).
class BitgetAuthInterceptor extends Interceptor {
  final String apiKey;
  final String apiSecret;
  final String passphrase;

  BitgetAuthInterceptor({
    required this.apiKey,
    required this.apiSecret,
    required this.passphrase,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
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
      'ACCESS-KEY': apiKey,
      'ACCESS-SIGN': sign,
      'ACCESS-TIMESTAMP': timestamp,
      'ACCESS-PASSPHRASE': passphrase,
      'locale': 'en-US',
      'Content-Type': 'application/json',
    });

    handler.next(options);
  }
}
