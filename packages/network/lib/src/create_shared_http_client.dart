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
