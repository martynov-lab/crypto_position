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
