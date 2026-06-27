import 'package:dio/dio.dart';

import 'bybit_auth_interceptor.dart';
import 'bybit_config.dart';

class DioClientFactory {
  Dio create({
    required BybitConfig config,
    required String apiKey,
    required String apiSecret,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseRestUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      BybitAuthInterceptor(
        apiKey: apiKey,
        apiSecret: apiSecret,
        recvWindow: config.recvWindow,
      ),
    );

    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    return dio;
  }
}
