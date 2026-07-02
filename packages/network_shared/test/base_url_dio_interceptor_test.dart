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
