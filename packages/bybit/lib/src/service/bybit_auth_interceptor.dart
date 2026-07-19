import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class BybitAuthInterceptor extends Interceptor {
  final String apiKey;
  final String apiSecret;
  final int recvWindow;

  BybitAuthInterceptor({
    required this.apiKey,
    required this.apiSecret,
    this.recvWindow = 20000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Bybit v5 signs the query string for GET and the raw JSON body for POST;
    // in both cases prefixed by timestamp + apiKey + recvWindow.
    final String signInput;
    if (options.method.toUpperCase() == 'GET') {
      final sortedKeys = options.queryParameters.keys.toList()..sort();
      final sortedParams = {
        for (final k in sortedKeys) k: options.queryParameters[k],
      };
      options.queryParameters = sortedParams;
      // Bybit verifies the signature against the query string exactly as it
      // appears on the wire, so sign the URL-encoded form Dio will send.
      signInput = options.uri.query;
    } else {
      signInput = options.data is String ? options.data as String : '';
    }

    final payload = '$timestamp$apiKey$recvWindow$signInput';
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final sign = hmac.convert(utf8.encode(payload)).toString();

    options.headers.addAll({
      'X-BAPI-API-KEY': apiKey,
      'X-BAPI-SIGN': sign,
      'X-BAPI-SIGN-TYPE': '2',
      'X-BAPI-TIMESTAMP': timestamp,
      'X-BAPI-RECV-WINDOW': '$recvWindow',
    });

    handler.next(options);
  }
}
