import 'dart:convert';

import 'package:bybit/bybit.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

String _expectedSign({
  required RequestOptions options,
  required String apiKey,
  required String apiSecret,
  required int recvWindow,
}) {
  final timestamp = options.headers['X-BAPI-TIMESTAMP'] as String;
  // Bybit verifies the signature against the query string exactly as it
  // appears on the wire (URL-encoded).
  final payload = '$timestamp$apiKey$recvWindow${options.uri.query}';
  return Hmac(sha256, utf8.encode(apiSecret))
      .convert(utf8.encode(payload))
      .toString();
}

void main() {
  group('BybitAuthInterceptor', () {
    late BybitAuthInterceptor interceptor;

    setUp(() {
      interceptor = BybitAuthInterceptor(
        apiKey: 'key',
        apiSecret: 'secret',
        recvWindow: 60000,
      );
    });

    RequestOptions run(Map<String, dynamic> queryParameters) {
      final options = RequestOptions(
        path: '/v5/position/closed-pnl',
        baseUrl: 'https://api.bybit.com',
        queryParameters: queryParameters,
      );
      interceptor.onRequest(options, RequestInterceptorHandler());
      return options;
    }

    test('signs simple params over the wire-encoded query string', () {
      final options = run({'accountType': 'UNIFIED'});

      expect(
        options.headers['X-BAPI-SIGN'],
        _expectedSign(
          options: options,
          apiKey: 'key',
          apiSecret: 'secret',
          recvWindow: 60000,
        ),
      );
    });

    test(
        'signs params needing URL encoding (pagination cursor with : and ,) '
        'over the wire-encoded query string', () {
      final options = run({
        'category': 'linear',
        'cursor': 'eb9212a2:1783164723672,318c46b8:1782909102398',
      });

      expect(
        options.headers['X-BAPI-SIGN'],
        _expectedSign(
          options: options,
          apiKey: 'key',
          apiSecret: 'secret',
          recvWindow: 60000,
        ),
      );
    });
  });
}
