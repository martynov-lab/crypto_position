# REST API Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the REST API layer from `rest_api_architecture.md`: `Result<T, E>` (core_shared), `RestClient` over Dio with typed exceptions (network_shared), and a reference feature module `bybit_account_shared` over Bybit `GET /v5/account/wallet-balance`, wired into the app via a DI factory.

**Architecture:** Three new Dart packages under `packages/`. Data flow: Repository → Api → RestClient → Dio. Errors propagate as `Result<T, Object>` — no layer above Dio throws. JSON → DTO via `json_serializable`, DTO → Model via extension mapper, Model is `@freezed`. BaseUrl is injected by `BaseUrlDioInterceptor`, not `BaseOptions.baseUrl`.

**Tech Stack:** Dart ^3.10.7, dio ^5.8.0, json_serializable, freezed 3.x, build_runner, package:test, provider (app side).

**Spec:** `docs/superpowers/specs/2026-07-02-rest-api-infrastructure-design.md`

## Global Constraints

- Dart SDK floor everywhere: `sdk: ^3.10.7` (matches root and existing packages).
- All new packages: `publish_to: 'none'`, `version: 0.1.0`.
- The existing `packages/bybit` package must NOT be modified.
- DTOs: `@JsonSerializable(checked: true, createToJson: false)`, `const` constructor, `factory fromJson`, JSON maps typed as `Map<String, Object?>`.
- Models: `@freezed`, domain types (`double` for amounts — approved instead of `Decimal`).
- No `LoggerMixin` / `logging` package (approved deviation from the guide).
- File naming: `snake_case` with `_dto`, `_model`, `_mapper`, `_api`, `_repository` suffixes.
- Commands below run from the repo root `C:\Users\arovit\Projects\crypto_position` unless a `cd` is shown. `dart`/`flutter` are on PATH.

---

### Task 1: `core_shared` package with `Result<T, E>`

**Files:**
- Create: `packages/core_shared/pubspec.yaml`
- Create: `packages/core_shared/lib/core_shared.dart`
- Create: `packages/core_shared/lib/src/result.dart`
- Test: `packages/core_shared/test/result_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `sealed class Result<T, E>` with `Result<U, E> map<U>(U Function(T value) function)`, `Result<T, F> mapErr<F>(F Function(E error) function)`, `B fold<B>(B Function(T value) ifOk, B Function(E error) ifErr)`; `final class Ok<T, E> extends Result<T, E>` with `final T value` and `const Ok(this.value)`; `final class Err<T, E> extends Result<T, E>` with `final E error` and `const Err(this.error)`. Import: `package:core_shared/core_shared.dart`.

- [ ] **Step 1: Scaffold the package**

Create `packages/core_shared/pubspec.yaml`:

```yaml
name: core_shared
description: Core shared utilities (Result type)
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.10.7

dev_dependencies:
  test: ^1.25.0
```

Run: `cd packages/core_shared && dart pub get`
Expected: `Got dependencies!`

- [ ] **Step 2: Write the failing test**

Create `packages/core_shared/test/result_test.dart`:

```dart
import 'package:core_shared/core_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('map transforms Ok value and keeps Err untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      final mappedOk = ok.map((value) => value * 10);
      final mappedErr = err.map((value) => value * 10);

      expect(mappedOk, isA<Ok<int, String>>().having((r) => r.value, 'value', 20));
      expect(mappedErr, isA<Err<int, String>>().having((r) => r.error, 'error', 'boom'));
    });

    test('mapErr transforms Err error and keeps Ok untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      final mappedOk = ok.mapErr((error) => error.length);
      final mappedErr = err.mapErr((error) => error.length);

      expect(mappedOk, isA<Ok<int, int>>().having((r) => r.value, 'value', 2));
      expect(mappedErr, isA<Err<int, int>>().having((r) => r.error, 'error', 4));
    });

    test('fold calls ifOk for Ok and ifErr for Err', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      expect(ok.fold((value) => 'ok:$value', (error) => 'err:$error'), 'ok:2');
      expect(err.fold((value) => 'ok:$value', (error) => 'err:$error'), 'err:boom');
    });

    test('supports pattern matching via switch', () {
      const Result<int, String> ok = Ok(42);

      final label = switch (ok) {
        Ok(:final value) => 'value=$value',
        Err(:final error) => 'error=$error',
      };

      expect(label, 'value=42');
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/core_shared && dart test`
Expected: FAIL — compilation error, `package:core_shared/core_shared.dart` does not exist.

- [ ] **Step 4: Write the implementation**

Create `packages/core_shared/lib/src/result.dart`:

```dart
/// Result of an operation: either [Ok] with a value or [Err] with an error.
///
/// Used instead of exceptions to propagate API call results.
sealed class Result<T, E> {
  const Result();

  Result<U, E> map<U>(U Function(T value) function) => switch (this) {
        Ok(:final value) => Ok(function(value)),
        Err(:final error) => Err(error),
      };

  Result<T, F> mapErr<F>(F Function(E error) function) => switch (this) {
        Ok(:final value) => Ok(value),
        Err(:final error) => Err(function(error)),
      };

  B fold<B>(B Function(T value) ifOk, B Function(E error) ifErr) =>
      switch (this) {
        Ok(:final value) => ifOk(value),
        Err(:final error) => ifErr(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  final E error;

  const Err(this.error);

  @override
  String toString() => 'Err($error)';
}
```

Create `packages/core_shared/lib/core_shared.dart`:

```dart
export 'src/result.dart';
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/core_shared && dart test`
Expected: `All tests passed!` (4 tests)

- [ ] **Step 6: Analyze and commit**

Run: `dart analyze packages/core_shared`
Expected: `No issues found!`

```bash
git add packages/core_shared
git commit -m "feat: add core_shared package with Result type"
```

---

### Task 2: `network_shared` package — exception hierarchy

**Files:**
- Create: `packages/network_shared/pubspec.yaml`
- Create: `packages/network_shared/lib/network_shared.dart`
- Create: `packages/network_shared/lib/src/rest_client/rest_client_exception.dart`
- Test: `packages/network_shared/test/rest_client_exception_test.dart`

**Interfaces:**
- Consumes: nothing (exceptions are plain Dart).
- Produces: `abstract base class RestClientException implements Exception` with `final String message`, `final int? statusCode`, `final Object? cause` and const constructor `({required String message, int? statusCode, Object? cause})`. Final subclasses with the same named parameters: `ClientException`, `ConnectionException`, `InternalServerException`, `WrongResponseTypeException`, and `CustomBackendException` which adds `required Map<String, Object?> error`. Import: `package:network_shared/network_shared.dart`.

- [ ] **Step 1: Scaffold the package**

Create `packages/network_shared/pubspec.yaml`:

```yaml
name: network_shared
description: RestClient wrapper over Dio returning Result
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.10.7

dependencies:
  core_shared:
    path: ../core_shared
  dio: ^5.8.0+1

dev_dependencies:
  test: ^1.25.0
```

Run: `cd packages/network_shared && dart pub get`
Expected: `Got dependencies!`

- [ ] **Step 2: Write the failing test**

Create `packages/network_shared/test/rest_client_exception_test.dart`:

```dart
import 'package:network_shared/network_shared.dart';
import 'package:test/test.dart';

void main() {
  group('RestClientException hierarchy', () {
    test('all subclasses are RestClientException and Exception', () {
      const exceptions = <RestClientException>[
        ClientException(message: 'client'),
        ConnectionException(message: 'connection'),
        CustomBackendException(message: 'backend', error: {'detail': 'oops'}),
        InternalServerException(message: 'server', statusCode: 500),
        WrongResponseTypeException(message: 'type'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<Exception>());
      }
    });

    test('CustomBackendException exposes the server error map', () {
      const exception = CustomBackendException(
        message: 'backend',
        error: {'detail': 'oops'},
        statusCode: 400,
      );

      expect(exception.error, {'detail': 'oops'});
      expect(exception.statusCode, 400);
    });

    test('toString contains message and statusCode', () {
      const exception = ClientException(message: 'bad request', statusCode: 400);

      expect(exception.toString(), contains('bad request'));
      expect(exception.toString(), contains('400'));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/network_shared && dart test`
Expected: FAIL — compilation error, library does not exist.

- [ ] **Step 4: Write the implementation**

Create `packages/network_shared/lib/src/rest_client/rest_client_exception.dart`:

```dart
/// Base class for all errors produced by [RestClient].
abstract base class RestClientException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const RestClientException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';
}

/// 4xx and other client-side HTTP errors.
final class ClientException extends RestClientException {
  const ClientException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}

/// Timeouts and connectivity failures.
final class ConnectionException extends RestClientException {
  const ConnectionException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}

/// The server returned a structured error body.
final class CustomBackendException extends RestClientException {
  /// Error body from the server.
  final Map<String, Object?> error;

  const CustomBackendException({
    required super.message,
    required this.error,
    super.statusCode,
    super.cause,
  });
}

/// 5xx errors without a structured body.
final class InternalServerException extends RestClientException {
  const InternalServerException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}

/// The response body does not match the expected generic type.
final class WrongResponseTypeException extends RestClientException {
  const WrongResponseTypeException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}
```

Create `packages/network_shared/lib/network_shared.dart`:

```dart
export 'src/rest_client/rest_client_exception.dart';
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/network_shared && dart test`
Expected: `All tests passed!` (3 tests)

- [ ] **Step 6: Commit**

```bash
git add packages/network_shared
git commit -m "feat: add network_shared package with RestClientException hierarchy"
```

---

### Task 3: `RestClient`

**Files:**
- Create: `packages/network_shared/lib/src/rest_client/rest_client.dart`
- Modify: `packages/network_shared/lib/network_shared.dart`
- Test: `packages/network_shared/test/rest_client_test.dart`

**Interfaces:**
- Consumes: `Result`, `Ok`, `Err` from `package:core_shared/core_shared.dart`; exceptions from Task 2.
- Produces: `class RestClient` with `const RestClient(Dio dio)` and methods:
  - `Future<Result<T, Object>> get<T>(String path, {Map<String, Object>? headers, Map<String, Object?>? queryParams})`
  - `Future<Result<T, Object>> post<T>(String path, {Object? body, Map<String, Object>? headers, Map<String, Object?>? queryParams, String? contentType})`
  - `put<T>`, `patch<T>` — same signature as `post<T>`
  - `delete<T>`, `head<T>` — same signature as `get<T>`
  Never throws; all failures are `Err` with a `RestClientException`.

- [ ] **Step 1: Write the failing tests**

Create `packages/network_shared/test/rest_client_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';
import 'package:network_shared/network_shared.dart';
import 'package:test/test.dart';

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/network_shared && dart test test/rest_client_test.dart`
Expected: FAIL — `RestClient` is not defined.

- [ ] **Step 3: Write the implementation**

Create `packages/network_shared/lib/src/rest_client/rest_client.dart`:

```dart
import 'dart:convert';

import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';

import 'rest_client_exception.dart';

/// Wrapper over [Dio]. All methods return [Result] and never throw.
class RestClient {
  final Dio _dio;

  const RestClient(this._dio);

  Future<Result<T, Object>> get<T>(
    String path, {
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'GET',
        headers: headers,
        queryParams: queryParams,
      );

  Future<Result<T, Object>> post<T>(
    String path, {
    Object? body,
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
    String? contentType,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'POST',
        body: body,
        headers: headers,
        queryParams: queryParams,
        contentType: contentType,
      );

  Future<Result<T, Object>> put<T>(
    String path, {
    Object? body,
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
    String? contentType,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'PUT',
        body: body,
        headers: headers,
        queryParams: queryParams,
        contentType: contentType,
      );

  Future<Result<T, Object>> patch<T>(
    String path, {
    Object? body,
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
    String? contentType,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'PATCH',
        body: body,
        headers: headers,
        queryParams: queryParams,
        contentType: contentType,
      );

  Future<Result<T, Object>> delete<T>(
    String path, {
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'DELETE',
        headers: headers,
        queryParams: queryParams,
      );

  Future<Result<T, Object>> head<T>(
    String path, {
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
  }) =>
      _sendRequest<T>(
        path: path,
        method: 'HEAD',
        headers: headers,
        queryParams: queryParams,
      );

  Future<Result<T, Object>> _sendRequest<T>({
    required String path,
    required String method,
    Object? body,
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
    String? contentType,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: encodeBody(body, contentType),
        queryParameters: queryParams,
        options: Options(
          method: method,
          headers: headers,
          contentType: contentType ?? Headers.jsonContentType,
        ),
      );

      final data = response.data;
      if (data is! T) {
        return Err(
          WrongResponseTypeException(
            message: 'Expected $T, got ${data.runtimeType}',
            statusCode: response.statusCode,
          ),
        );
      }

      return Ok(data);
    } on DioException catch (exception) {
      return Err(_mapDioException(exception));
    } on Object catch (exception) {
      return Err(
        ClientException(message: 'Unexpected error', cause: exception),
      );
    }
  }

  /// Encodes [body] to JSON; [FormData] and form-url-encoded pass through.
  static Object? encodeBody(Object? body, String? contentType) {
    if (body == null || body is FormData) return body;
    if (contentType == Headers.formUrlEncodedContentType) return body;
    return jsonEncode(body);
  }

  static RestClientException _mapDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ConnectionException(
          message: exception.message ?? 'Connection error',
          statusCode: statusCode,
          cause: exception,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        final data = exception.response?.data;
        if (data is Map<String, Object?>) {
          return CustomBackendException(
            message: exception.message ?? 'Backend error',
            error: data,
            statusCode: statusCode,
            cause: exception,
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return InternalServerException(
            message: exception.message ?? 'Internal server error',
            statusCode: statusCode,
            cause: exception,
          );
        }
        return ClientException(
          message: exception.message ?? 'Client error',
          statusCode: statusCode,
          cause: exception,
        );
    }
  }
}
```

Update `packages/network_shared/lib/network_shared.dart` to:

```dart
export 'src/rest_client/rest_client.dart';
export 'src/rest_client/rest_client_exception.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/network_shared && dart test`
Expected: `All tests passed!` (exception tests + 8 RestClient tests)

- [ ] **Step 5: Commit**

```bash
git add packages/network_shared
git commit -m "feat: add RestClient returning Result with typed error mapping"
```

---

### Task 4: `BaseUrlDioInterceptor` and `createSharedHttpClient`

**Files:**
- Create: `packages/network_shared/lib/src/interceptors/base_url_dio_interceptor.dart`
- Create: `packages/network_shared/lib/src/create_shared_http_client.dart`
- Modify: `packages/network_shared/lib/network_shared.dart`
- Test: `packages/network_shared/test/base_url_dio_interceptor_test.dart`

**Interfaces:**
- Consumes: `dio` only.
- Produces: `class BaseUrlDioInterceptor extends Interceptor` with `const BaseUrlDioInterceptor({required Uri Function() getHost})`; `Dio createSharedHttpClient()` returning a `Dio` with 10-second connect/send/receive timeouts and no baseUrl (set by the interceptor).

- [ ] **Step 1: Write the failing test**

Create `packages/network_shared/test/base_url_dio_interceptor_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:network_shared/network_shared.dart';
import 'package:test/test.dart';

void main() {
  test('BaseUrlDioInterceptor sets baseUrl from getHost on each request', () {
    var host = Uri.parse('https://first.example.com');
    final interceptor = BaseUrlDioInterceptor(getHost: () => host);

    final first = RequestOptions(path: '/x');
    interceptor.onRequest(first, RequestInterceptorHandler());
    expect(first.baseUrl, 'https://first.example.com');

    // Dynamic host change is picked up without recreating the interceptor.
    host = Uri.parse('https://second.example.com');
    final second = RequestOptions(path: '/x');
    interceptor.onRequest(second, RequestInterceptorHandler());
    expect(second.baseUrl, 'https://second.example.com');
  });

  test('createSharedHttpClient configures 10s timeouts', () {
    final dio = createSharedHttpClient();

    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.sendTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    expect(dio.options.baseUrl, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/network_shared && dart test test/base_url_dio_interceptor_test.dart`
Expected: FAIL — `BaseUrlDioInterceptor` is not defined.

- [ ] **Step 3: Write the implementation**

Create `packages/network_shared/lib/src/interceptors/base_url_dio_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

/// Injects the baseUrl on every request, allowing it to change dynamically
/// without recreating the Dio client.
class BaseUrlDioInterceptor extends Interceptor {
  final Uri Function() _getHost;

  const BaseUrlDioInterceptor({required Uri Function() getHost})
      : _getHost = getHost;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.baseUrl = _getHost().toString();
    handler.next(options);
  }
}
```

Create `packages/network_shared/lib/src/create_shared_http_client.dart`:

```dart
import 'package:dio/dio.dart';

/// Creates a Dio client with shared defaults.
///
/// BaseUrl is intentionally left empty — inject it via [BaseUrlDioInterceptor].
Dio createSharedHttpClient() => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
```

Update `packages/network_shared/lib/network_shared.dart` to:

```dart
export 'src/create_shared_http_client.dart';
export 'src/interceptors/base_url_dio_interceptor.dart';
export 'src/rest_client/rest_client.dart';
export 'src/rest_client/rest_client_exception.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/network_shared && dart test`
Expected: `All tests passed!`

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze packages/network_shared`
Expected: `No issues found!`

```bash
git add packages/network_shared
git commit -m "feat: add BaseUrlDioInterceptor and createSharedHttpClient"
```

---

### Task 5: `bybit_account_shared` — DTO, Model, Mapper (with codegen)

**Files:**
- Create: `packages/bybit_account_shared/pubspec.yaml`
- Create: `packages/bybit_account_shared/lib/bybit_account_shared.dart`
- Create: `packages/bybit_account_shared/lib/src/api/dto/wallet_balance_dto.dart`
- Create: `packages/bybit_account_shared/lib/src/domain/models/wallet_balance_model.dart`
- Create: `packages/bybit_account_shared/lib/src/api/mappers/wallet_balance_mapper.dart`
- Generated: `wallet_balance_dto.g.dart`, `wallet_balance_model.freezed.dart` (via build_runner)
- Test: `packages/bybit_account_shared/test/wallet_balance_mapper_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks (pure data layer).
- Produces:
  - `WalletBalanceDto{String accountType, String totalEquity, String totalWalletBalance, List<CoinBalanceDto> coins}` with `factory WalletBalanceDto.fromJson(Map<String, Object?> json)` (JSON key for coins is `coin`).
  - `CoinBalanceDto{String coin, String equity, String walletBalance, String usdValue}` with `fromJson`.
  - `WalletBalanceModel{String accountType, double totalEquity, double totalWalletBalance, List<CoinBalanceModel> coins}` (freezed).
  - `CoinBalanceModel{String coin, double equity, double walletBalance, double usdValue}` (freezed).
  - `extension WalletBalanceMapper on WalletBalanceDto { WalletBalanceModel toModel(); }` — empty strings parse to `0`.
  - Import: `package:bybit_account_shared/bybit_account_shared.dart`.

- [ ] **Step 1: Scaffold the package**

Create `packages/bybit_account_shared/pubspec.yaml`:

```yaml
name: bybit_account_shared
description: Bybit account feature module (reference REST API module)
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.10.7

dependencies:
  core_shared:
    path: ../core_shared
  network_shared:
    path: ../network_shared
  dio: ^5.8.0+1
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.15
  freezed: ^3.0.6
  json_serializable: ^6.9.5
  test: ^1.25.0
```

Run: `cd packages/bybit_account_shared && dart pub get`
Expected: `Got dependencies!` (if version resolution fails, relax the failing constraint to the latest resolvable major, e.g. `freezed: ^3.0.0`)

- [ ] **Step 2: Write the failing mapper test**

Create `packages/bybit_account_shared/test/wallet_balance_mapper_test.dart`:

```dart
import 'package:bybit_account_shared/bybit_account_shared.dart';
import 'package:test/test.dart';

void main() {
  group('WalletBalanceMapper', () {
    test('converts DTO to Model with parsed amounts', () {
      const dto = WalletBalanceDto(
        accountType: 'UNIFIED',
        totalEquity: '123.45',
        totalWalletBalance: '100.5',
        coins: [
          CoinBalanceDto(
            coin: 'BTC',
            equity: '0.5',
            walletBalance: '0.4',
            usdValue: '20000.1',
          ),
        ],
      );

      final model = dto.toModel();

      expect(model.accountType, 'UNIFIED');
      expect(model.totalEquity, 123.45);
      expect(model.totalWalletBalance, 100.5);
      expect(model.coins, hasLength(1));
      expect(model.coins.first.coin, 'BTC');
      expect(model.coins.first.equity, 0.5);
      expect(model.coins.first.usdValue, 20000.1);
    });

    test('parses empty strings as zero (Bybit returns "" for some fields)',
        () {
      const dto = WalletBalanceDto(
        accountType: 'UNIFIED',
        totalEquity: '',
        totalWalletBalance: '',
        coins: [],
      );

      final model = dto.toModel();

      expect(model.totalEquity, 0);
      expect(model.totalWalletBalance, 0);
    });

    test('fromJson maps the "coin" JSON key to coins', () {
      final dto = WalletBalanceDto.fromJson({
        'accountType': 'UNIFIED',
        'totalEquity': '1',
        'totalWalletBalance': '2',
        'coin': [
          {
            'coin': 'ETH',
            'equity': '3',
            'walletBalance': '4',
            'usdValue': '5',
          },
        ],
      });

      expect(dto.coins.single.coin, 'ETH');
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/bybit_account_shared && dart test`
Expected: FAIL — library does not exist.

- [ ] **Step 4: Write DTO, Model, Mapper**

Create `packages/bybit_account_shared/lib/src/api/dto/wallet_balance_dto.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'wallet_balance_dto.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class WalletBalanceDto {
  final String accountType;
  final String totalEquity;
  final String totalWalletBalance;
  @JsonKey(name: 'coin')
  final List<CoinBalanceDto> coins;

  const WalletBalanceDto({
    required this.accountType,
    required this.totalEquity,
    required this.totalWalletBalance,
    required this.coins,
  });

  factory WalletBalanceDto.fromJson(Map<String, Object?> json) =>
      _$WalletBalanceDtoFromJson(json);
}

@JsonSerializable(checked: true, createToJson: false)
class CoinBalanceDto {
  final String coin;
  final String equity;
  final String walletBalance;
  final String usdValue;

  const CoinBalanceDto({
    required this.coin,
    required this.equity,
    required this.walletBalance,
    required this.usdValue,
  });

  factory CoinBalanceDto.fromJson(Map<String, Object?> json) =>
      _$CoinBalanceDtoFromJson(json);
}
```

Create `packages/bybit_account_shared/lib/src/domain/models/wallet_balance_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_balance_model.freezed.dart';

@freezed
abstract class WalletBalanceModel with _$WalletBalanceModel {
  const factory WalletBalanceModel({
    required String accountType,
    required double totalEquity,
    required double totalWalletBalance,
    required List<CoinBalanceModel> coins,
  }) = _WalletBalanceModel;
}

@freezed
abstract class CoinBalanceModel with _$CoinBalanceModel {
  const factory CoinBalanceModel({
    required String coin,
    required double equity,
    required double walletBalance,
    required double usdValue,
  }) = _CoinBalanceModel;
}
```

Create `packages/bybit_account_shared/lib/src/api/mappers/wallet_balance_mapper.dart`:

```dart
import '../../domain/models/wallet_balance_model.dart';
import '../dto/wallet_balance_dto.dart';

extension WalletBalanceMapper on WalletBalanceDto {
  WalletBalanceModel toModel() => WalletBalanceModel(
        accountType: accountType,
        totalEquity: _parseAmount(totalEquity),
        totalWalletBalance: _parseAmount(totalWalletBalance),
        coins: coins.map((coin) => coin.toModel()).toList(),
      );
}

extension CoinBalanceMapper on CoinBalanceDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: coin,
        equity: _parseAmount(equity),
        walletBalance: _parseAmount(walletBalance),
        usdValue: _parseAmount(usdValue),
      );
}

/// Bybit returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
```

Create `packages/bybit_account_shared/lib/bybit_account_shared.dart`:

```dart
export 'src/api/dto/wallet_balance_dto.dart';
export 'src/api/mappers/wallet_balance_mapper.dart';
export 'src/domain/models/wallet_balance_model.dart';
```

- [ ] **Step 5: Run code generation**

Run: `cd packages/bybit_account_shared && dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — creates `wallet_balance_dto.g.dart` and `wallet_balance_model.freezed.dart`.

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd packages/bybit_account_shared && dart test`
Expected: `All tests passed!` (3 tests)

- [ ] **Step 7: Commit**

```bash
git add packages/bybit_account_shared
git commit -m "feat: add bybit_account_shared DTO, model and mapper"
```

---

### Task 6: `bybit_account_shared` — Api and Repository

**Files:**
- Create: `packages/bybit_account_shared/lib/src/api/bybit_account_api.dart`
- Create: `packages/bybit_account_shared/lib/src/domain/bybit_account_repository.dart`
- Modify: `packages/bybit_account_shared/lib/bybit_account_shared.dart`
- Test: `packages/bybit_account_shared/test/bybit_account_api_test.dart`

**Interfaces:**
- Consumes: `RestClient` (Task 3), `Result`/`Ok`/`Err` (Task 1), `WalletBalanceDto` + `WalletBalanceMapper` (Task 5).
- Produces:
  - `class BybitAccountApi` with `const BybitAccountApi(RestClient client)` and `Future<Result<WalletBalanceDto, Object>> fetchWalletBalance({String accountType = 'UNIFIED'})`.
  - `class BybitAccountRepository` with `const BybitAccountRepository({required BybitAccountApi bybitAccountApi})` and `Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({String accountType = 'UNIFIED'})`.

- [ ] **Step 1: Write the failing tests**

Create `packages/bybit_account_shared/test/bybit_account_api_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:bybit_account_shared/bybit_account_shared.dart';
import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';
import 'package:network_shared/network_shared.dart';
import 'package:test/test.dart';

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/bybit_account_shared && dart test test/bybit_account_api_test.dart`
Expected: FAIL — `BybitAccountApi` is not defined.

- [ ] **Step 3: Write the implementation**

Create `packages/bybit_account_shared/lib/src/api/bybit_account_api.dart`:

```dart
import 'package:core_shared/core_shared.dart';
import 'package:network_shared/network_shared.dart';

import 'dto/wallet_balance_dto.dart';

class BybitAccountApi {
  final RestClient _client;

  const BybitAccountApi(this._client);

  Future<Result<WalletBalanceDto, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/account/wallet-balance',
      queryParams: {'accountType': accountType},
    );

    return response.fold<Result<WalletBalanceDto, Object>>(
      (data) {
        try {
          final result = data['result'] as Map<String, Object?>;
          final list = result['list'] as List<Object?>;
          if (list.isEmpty) {
            return Ok(
              WalletBalanceDto(
                accountType: accountType,
                totalEquity: '0',
                totalWalletBalance: '0',
                coins: const [],
              ),
            );
          }
          return Ok(
            WalletBalanceDto.fromJson(list.first! as Map<String, Object?>),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }
}
```

Create `packages/bybit_account_shared/lib/src/domain/bybit_account_repository.dart`:

```dart
import 'package:core_shared/core_shared.dart';

import '../api/bybit_account_api.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import 'models/wallet_balance_model.dart';

class BybitAccountRepository {
  final BybitAccountApi _api;

  const BybitAccountRepository({
    required BybitAccountApi bybitAccountApi,
  }) : _api = bybitAccountApi;

  Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final result = await _api.fetchWalletBalance(accountType: accountType);

    return result.map((dto) => dto.toModel());
  }
}
```

Update `packages/bybit_account_shared/lib/bybit_account_shared.dart` to:

```dart
export 'src/api/bybit_account_api.dart';
export 'src/api/dto/wallet_balance_dto.dart';
export 'src/api/mappers/wallet_balance_mapper.dart';
export 'src/domain/bybit_account_repository.dart';
export 'src/domain/models/wallet_balance_model.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/bybit_account_shared && dart test`
Expected: `All tests passed!` (mapper + api/repository tests)

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze packages/bybit_account_shared`
Expected: `No issues found!`

```bash
git add packages/bybit_account_shared
git commit -m "feat: add BybitAccountApi and BybitAccountRepository"
```

---

### Task 7: DI factory and app wiring

**Files:**
- Modify: `pubspec.yaml` (root)
- Create: `lib/src/bybit_account_repository_factory.dart`
- Modify: `lib/src/position_provider.dart`

**Interfaces:**
- Consumes: `createSharedHttpClient`, `BaseUrlDioInterceptor`, `RestClient` (network_shared); `BybitAccountApi`, `BybitAccountRepository` (bybit_account_shared); `BybitConfig`, `BybitAuthInterceptor` (existing `bybit` package — `BybitAuthInterceptor({required String apiKey, required String apiSecret, required int recvWindow})`).
- Produces: `class BybitAccountRepositoryFactory` with `BybitAccountRepositoryFactory(BybitConfig config)` and `BybitAccountRepository create({required String apiKey, required String apiSecret})`, registered in `PositionProvider`.

- [ ] **Step 1: Add path dependencies to the app**

In root `pubspec.yaml`, add to `dependencies:` (after the existing `ui_kit` entry):

```yaml
  core_shared:
    path: packages/core_shared
  network_shared:
    path: packages/network_shared
  bybit_account_shared:
    path: packages/bybit_account_shared
```

Run: `flutter pub get`
Expected: resolves without errors.

- [ ] **Step 2: Create the factory**

Create `lib/src/bybit_account_repository_factory.dart`:

```dart
import 'package:bybit/bybit.dart';
import 'package:bybit_account_shared/bybit_account_shared.dart';
import 'package:network_shared/network_shared.dart';

/// Builds the BybitAccountRepository graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// repository cannot be provided directly at app start.
class BybitAccountRepositoryFactory {
  final BybitConfig _config;

  const BybitAccountRepositoryFactory(this._config);

  BybitAccountRepository create({
    required String apiKey,
    required String apiSecret,
  }) {
    final dio = createSharedHttpClient()
      ..interceptors.addAll([
        // BaseUrl must be set before the auth interceptor signs the request.
        BaseUrlDioInterceptor(getHost: () => Uri.parse(_config.baseRestUrl)),
        BybitAuthInterceptor(
          apiKey: apiKey,
          apiSecret: apiSecret,
          recvWindow: _config.recvWindow,
        ),
      ]);

    return BybitAccountRepository(
      bybitAccountApi: BybitAccountApi(RestClient(dio)),
    );
  }
}
```

Note: if `BybitAuthInterceptor`'s actual constructor differs (check `packages/bybit/lib/service/bybit_auth_interceptor.dart`), match it exactly — do not modify the bybit package.

- [ ] **Step 3: Register in PositionProvider**

In `lib/src/position_provider.dart`, add the import:

```dart
import 'package:crypto_position/src/bybit_account_repository_factory.dart';
```

and add to the `providers:` list after the `WsClientFactory` entry:

```dart
      Provider<BybitAccountRepositoryFactory>(
        create: (context) =>
            BybitAccountRepositoryFactory(context.read<BybitConfig>()),
      ),
```

- [ ] **Step 4: Verify the app compiles**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: existing app tests pass (or fail identically to before the change — verify with `git stash`/`git stash pop` only if failures appear).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/bybit_account_repository_factory.dart lib/src/position_provider.dart
git commit -m "feat: wire BybitAccountRepositoryFactory into app DI"
```
