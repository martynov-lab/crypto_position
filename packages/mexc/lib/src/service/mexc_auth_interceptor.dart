import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Signs MEXC contract (futures) REST requests.
///
/// Signature (hex): `HMAC-SHA256(secret, accessKey + timestamp + paramString)`.
/// For GET/DELETE the paramString is the query parameters sorted by key and
/// joined as `key=value&...`; for POST it is the raw JSON body. [timestamp] is
/// Unix epoch **milliseconds** and is echoed in the `Request-Time` header.
class MexcAuthInterceptor extends Interceptor {
  final String apiKey;
  final String apiSecret;

  MexcAuthInterceptor({required this.apiKey, required this.apiSecret});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final method = options.method.toUpperCase();

    final String paramString;
    if (method == 'GET' || method == 'DELETE') {
      final params = options.uri.queryParameters;
      final keys = params.keys.toList()..sort();
      paramString = keys.map((k) => '$k=${params[k]}').join('&');
    } else {
      paramString = options.data is String ? options.data as String : '';
    }

    final signTarget = '$apiKey$timestamp$paramString';
    final signature = Hmac(sha256, utf8.encode(apiSecret))
        .convert(utf8.encode(signTarget))
        .toString();

    options.headers.addAll({
      'ApiKey': apiKey,
      'Request-Time': timestamp,
      'Signature': signature,
      'Content-Type': 'application/json',
    });

    handler.next(options);
  }
}
