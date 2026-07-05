import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub adapter: returns a canned response or throws, capturing the request.
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

ResponseBody _jsonResponse(Object? body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

(RestClient, _StubAdapter) _createClient(
  ResponseBody Function(RequestOptions options) handler,
) {
  final adapter = _StubAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..httpClientAdapter = adapter;
  return (RestClient(dio), adapter);
}

void main() {
  group('RestClient', () {
    test('get returns Ok with decoded Map on 200', () async {
      final (client, _) =
          _createClient((options) => _jsonResponse({'name': 'neo'}, 200));

      final result = await client.get<Map<String, Object?>>('/user');

      expect(
        result,
        isA<Ok<Map<String, Object?>, Object>>()
            .having((r) => r.value, 'value', {'name': 'neo'}),
      );
    });

    test('post encodes body as JSON and passes query params', () async {
      final (client, adapter) =
          _createClient((options) => _jsonResponse({'ok': true}, 200));

      await client.post<Map<String, Object?>>(
        '/items',
        body: {'title': 'x'},
        queryParams: {'lang': 'en'},
        headers: {'X-Custom': 'v'},
      );

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.data, jsonEncode({'title': 'x'}));
      expect(request.queryParameters, {'lang': 'en'});
      expect(request.headers['X-Custom'], 'v');
    });

    test('returns Err(WrongResponseTypeException) when data is not T',
        () async {
      final (client, _) =
          _createClient((options) => _jsonResponse({'name': 'neo'}, 200));

      final result = await client.get<String>('/user');

      expect(
        result,
        isA<Err<String, Object>>()
            .having((r) => r.error, 'error', isA<WrongResponseTypeException>()),
      );
    });

    test('maps 400 with Map body to CustomBackendException', () async {
      final (client, _) =
          _createClient((options) => _jsonResponse({'detail': 'bad'}, 400));

      final result = await client.get<Map<String, Object?>>('/user');

      expect(
        result,
        isA<Err<Map<String, Object?>, Object>>().having(
          (r) => r.error,
          'error',
          isA<CustomBackendException>()
              .having((e) => e.error, 'error', {'detail': 'bad'})
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('maps 500 with non-Map body to InternalServerException', () async {
      final (client, _) =
          _createClient((options) => _jsonResponse('oops', 500));

      final result = await client.get<Map<String, Object?>>('/user');

      expect(
        result,
        isA<Err<Map<String, Object?>, Object>>().having(
          (r) => r.error,
          'error',
          isA<InternalServerException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('maps 404 with non-Map body to ClientException', () async {
      final (client, _) =
          _createClient((options) => _jsonResponse('nope', 404));

      final result = await client.get<Map<String, Object?>>('/user');

      expect(
        result,
        isA<Err<Map<String, Object?>, Object>>()
            .having((r) => r.error, 'error', isA<ClientException>()),
      );
    });

    test('maps connection timeout to ConnectionException', () async {
      final (client, _) = _createClient(
        (options) => throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: const Duration(seconds: 1),
        ),
      );

      final result = await client.get<Map<String, Object?>>('/user');

      expect(
        result,
        isA<Err<Map<String, Object?>, Object>>()
            .having((r) => r.error, 'error', isA<ConnectionException>()),
      );
    });

    test('delete and head use correct HTTP methods', () async {
      final (client, adapter) =
          _createClient((options) => _jsonResponse({'ok': true}, 200));

      await client.delete<Map<String, Object?>>('/items/1');
      expect(adapter.lastRequest!.method, 'DELETE');

      await client.head<Map<String, Object?>>('/items/1');
      expect(adapter.lastRequest!.method, 'HEAD');
    });
  });
}
