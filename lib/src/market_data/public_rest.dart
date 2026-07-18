import 'package:network/network.dart';

/// Builds an unauthenticated [RestClient] pinned to [baseUrl], for public
/// market-data endpoints.
RestClient publicRestClient(String baseUrl) {
  final host = Uri.parse(baseUrl);
  return RestClient(
    createSharedHttpClient()
      ..interceptors.add(BaseUrlDioInterceptor(getHost: () => host)),
  );
}

/// Parses a possibly-string, possibly-num JSON field to a double.
double? asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Parses a possibly-string, possibly-num JSON field to an int.
int? asInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
