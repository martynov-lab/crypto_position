import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:gate/gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GateAuthInterceptor', () {
    test('signs GET requests with hex HMAC-SHA512 over the canonical string',
        () {
      final interceptor =
          GateAuthInterceptor(apiKey: 'my-key', apiSecret: 'my-secret');
      final options = RequestOptions(
        path: '/api/v4/futures/usdt/accounts',
        method: 'GET',
        baseUrl: 'https://api.gateio.ws',
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      final headers = options.headers;
      expect(headers['KEY'], 'my-key');
      final sign = headers['SIGN']! as String;
      final timestamp = headers['Timestamp']! as String;
      expect(sign, matches(RegExp(r'^[0-9a-f]{128}$')));

      // Recompute the expected signature to pin the canonical string format:
      // METHOD\npath\nquery\nSHA512(body)\ntimestamp, body empty for GET.
      final emptyHash = sha512.convert(utf8.encode('')).toString();
      final expectedString =
          'GET\n/api/v4/futures/usdt/accounts\n\n$emptyHash\n$timestamp';
      final expectedSign = Hmac(sha512, utf8.encode('my-secret'))
          .convert(utf8.encode(expectedString))
          .toString();
      expect(sign, expectedSign);
    });
  });
}
