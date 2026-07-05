import 'dart:convert';
import 'dart:typed_data';

import 'package:bybit/bybit.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  RequestOptions? lastRequest;

  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

(RestClient, _StubAdapter) _createClient(Object? body, int statusCode) {
  final adapter = _StubAdapter(
    (options) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..httpClientAdapter = adapter;
  return (RestClient(dio), adapter);
}

Map<String, Object?> _walletEnvelope(List<Object?> list) => {
      'retCode': 0,
      'retMsg': 'OK',
      'result': {'list': list},
    };

void main() {
  group('BybitAccountApi', () {
    test('parses wallet balance from the Bybit envelope', () async {
      final (client, adapter) = _createClient(
        _walletEnvelope([
          {
            'accountType': 'UNIFIED',
            'totalEquity': '10.5',
            'totalWalletBalance': '9.5',
            'coin': [
              {
                'coin': 'USDT',
                'equity': '9.5',
                'walletBalance': '9.5',
                'usdValue': '9.5',
                'unrealisedPnl': '0.5',
              },
            ],
          },
        ]),
        200,
      );
      final api = BybitAccountApi(client);

      final result = await api.fetchWalletBalance();

      expect(adapter.lastRequest!.path, contains('/v5/account/wallet-balance'));
      expect(adapter.lastRequest!.queryParameters['accountType'], 'UNIFIED');
      expect(
        result,
        isA<Ok<WalletBalanceDto, Object>>().having(
          (r) => r.value.totalEquity,
          'totalEquity',
          '10.5',
        ),
      );
    });

    test('returns empty DTO when the list is empty', () async {
      final (client, _) = _createClient(_walletEnvelope([]), 200);
      final api = BybitAccountApi(client);

      final result = await api.fetchWalletBalance();

      expect(
        result,
        isA<Ok<WalletBalanceDto, Object>>()
            .having((r) => r.value.totalEquity, 'totalEquity', '0')
            .having((r) => r.value.coins, 'coins', isEmpty),
      );
    });

    test('returns Err when the envelope shape is unexpected', () async {
      final (client, _) = _createClient({'retCode': 10001}, 200);
      final api = BybitAccountApi(client);

      final result = await api.fetchWalletBalance();

      expect(result, isA<Err<WalletBalanceDto, Object>>());
    });

    test('propagates RestClient errors', () async {
      final (client, _) = _createClient({'retMsg': 'invalid key'}, 401);
      final api = BybitAccountApi(client);

      final result = await api.fetchWalletBalance();

      expect(
        result,
        isA<Err<WalletBalanceDto, Object>>()
            .having((r) => r.error, 'error', isA<CustomBackendException>()),
      );
    });

    test('returns Err(CustomBackendException) when retCode != 0', () async {
      final (client, _) = _createClient(
        {
          'retCode': 10002,
          'retMsg': 'invalid request',
          'result': <String, Object?>{},
        },
        200,
      );
      final api = BybitAccountApi(client);

      final result = await api.fetchWalletBalance();

      expect(
        result,
        isA<Err<WalletBalanceDto, Object>>().having(
          (r) => r.error,
          'error',
          isA<CustomBackendException>()
              .having((e) => e.message, 'message', 'invalid request'),
        ),
      );
    });
  });

  group('BybitAccountRepository', () {
    test('maps DTO to Model', () async {
      final (client, _) = _createClient(
        _walletEnvelope([
          {
            'accountType': 'UNIFIED',
            'totalEquity': '10.5',
            'totalWalletBalance': '9.5',
            'coin': <Object?>[],
          },
        ]),
        200,
      );
      final repository = BybitAccountRepository(
        bybitAccountApi: BybitAccountApi(client),
      );

      final result = await repository.fetchWalletBalance();

      expect(
        result,
        isA<Ok<WalletBalanceModel, Object>>().having(
          (r) => r.value.totalEquity,
          'totalEquity',
          10.5,
        ),
      );
    });
  });
}
