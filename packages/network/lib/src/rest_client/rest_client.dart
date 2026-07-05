import 'dart:convert';

import 'package:core/core.dart';
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
  }) => _sendRequest<T>(
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
  }) => _sendRequest<T>(
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
  }) => _sendRequest<T>(
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
  }) => _sendRequest<T>(
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
  }) => _sendRequest<T>(
    path: path,
    method: 'DELETE',
    headers: headers,
    queryParams: queryParams,
  );

  Future<Result<T, Object>> head<T>(
    String path, {
    Map<String, Object>? headers,
    Map<String, Object?>? queryParams,
  }) => _sendRequest<T>(
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
      case DioExceptionType.transformTimeout:
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
