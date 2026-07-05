import 'dart:convert';
import 'dart:typed_data';

import 'package:bybit/bybit.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _StubAdapter implements HttpClientAdapter {
  final List<Map<String, Object?>> responses;
  final requests = <RequestOptions>[];
  var _call = 0;

  _StubAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(responses[_call++]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(BybitAccountApi, _StubAdapter) _createApi(
  List<Map<String, Object?>> responses,
) {
  final adapter = _StubAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..httpClientAdapter = adapter;
  return (BybitAccountApi(RestClient(dio)), adapter);
}

Map<String, Object?> _pnlItem(String symbol) => {
      'symbol': symbol,
      'orderId': 'o',
      'side': 'Buy',
      'qty': '1',
      'orderPrice': '1',
      'orderType': 'Market',
      'avgEntryPrice': '1',
      'avgExitPrice': '1',
      'closedPnl': '1',
      'leverage': '1',
      'cumEntryValue': '1',
      'cumExitValue': '1',
      'createdTime': '1',
      'updatedTime': '1',
    };

Map<String, Object?> _page(List<Object?> list, {String cursor = ''}) => {
      'retCode': 0,
      'retMsg': 'OK',
      'result': {'list': list, 'nextPageCursor': cursor},
    };

void main() {
  group('BybitAccountApi.fetchClosedPnl', () {
    test('collects all pages, decoding the URL-encoded cursor', () async {
      final (api, adapter) = _createApi([
        _page([_pnlItem('BTCUSDT')], cursor: 'a%3A1%2Cb%3A2'),
        _page([_pnlItem('ETHUSDT')]),
      ]);

      final result = await api.fetchClosedPnl(category: 'linear');

      expect(
        result,
        isA<Ok<List<ClosedPnlDto>, Object>>()
            .having((r) => r.value.map((d) => d.symbol), 'symbols',
                ['BTCUSDT', 'ETHUSDT']),
      );
      expect(adapter.requests, hasLength(2));
      final second = adapter.requests[1];
      // Decoded before reuse, so the wire encodes it exactly once.
      expect(second.queryParameters['cursor'], 'a:1,b:2');
      expect(second.uri.query, isNot(contains('%25')));
    });

    test('splits ranges longer than 7 days into chunks', () async {
      // 15 days => 3 chunk requests (7 + 7 + 1).
      final (api, adapter) = _createApi([
        _page([_pnlItem('A')]),
        _page([_pnlItem('B')]),
        _page([_pnlItem('C')]),
      ]);
      const dayMs = 24 * 60 * 60 * 1000;

      final result = await api.fetchClosedPnl(
        category: 'linear',
        startTime: 0,
        endTime: 15 * dayMs,
      );

      expect(adapter.requests, hasLength(3));
      expect(adapter.requests[0].queryParameters['startTime'], 0);
      expect(adapter.requests[0].queryParameters['endTime'], 7 * dayMs);
      expect(adapter.requests[1].queryParameters['startTime'], 7 * dayMs);
      expect(adapter.requests[1].queryParameters['endTime'], 14 * dayMs);
      expect(adapter.requests[2].queryParameters['startTime'], 14 * dayMs);
      expect(adapter.requests[2].queryParameters['endTime'], 15 * dayMs);
      expect(
        result,
        isA<Ok<List<ClosedPnlDto>, Object>>()
            .having((r) => r.value, 'items', hasLength(3)),
      );
    });

    test('returns Err(CustomBackendException) when retCode != 0', () async {
      final (api, _) = _createApi([
        {
          'retCode': 10002,
          'retMsg': 'invalid request',
          'result': <String, Object?>{},
        },
      ]);

      final result = await api.fetchClosedPnl(category: 'linear');

      expect(
        result,
        isA<Err<List<ClosedPnlDto>, Object>>().having(
          (r) => r.error,
          'error',
          isA<CustomBackendException>()
              .having((e) => e.message, 'message', 'invalid request'),
        ),
      );
    });

    test('propagates RestClient errors', () async {
      final adapter = _StubAdapter([]);
      final dio = Dio(BaseOptions(
        baseUrl: 'https://example.com',
        connectTimeout: const Duration(milliseconds: 1),
      ))..httpClientAdapter = adapter;
      // Adapter with no scripted responses throws a RangeError inside dio,
      // which RestClient maps to a RestClientException.
      final api = BybitAccountApi(RestClient(dio));

      final result = await api.fetchClosedPnl(category: 'linear');

      expect(result, isA<Err<List<ClosedPnlDto>, Object>>());
    });
  });
}
