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
