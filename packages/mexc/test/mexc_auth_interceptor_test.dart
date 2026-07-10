import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:mexc/mexc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MexcAuthInterceptor', () {
    test('signs GET with hex HMAC-SHA256 over key+time+sortedQuery', () {
      final interceptor =
          MexcAuthInterceptor(apiKey: 'my-key', apiSecret: 'my-secret');
      final options = RequestOptions(
        path: '/api/v1/private/position/list/history_positions',
        method: 'GET',
        baseUrl: 'https://contract.mexc.com',
        queryParameters: {'page_size': '100', 'page_num': '1'},
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      final headers = options.headers;
      expect(headers['ApiKey'], 'my-key');
      final sign = headers['Signature']! as String;
      final ts = headers['Request-Time']! as String;
      expect(sign, matches(RegExp(r'^[0-9a-f]{64}$')));

      // Params must be sorted by key: page_num before page_size.
      const sortedParams = 'page_num=1&page_size=100';
      final expected = Hmac(sha256, utf8.encode('my-secret'))
          .convert(utf8.encode('my-key$ts$sortedParams'))
          .toString();
      expect(sign, expected);
    });
  });
}
