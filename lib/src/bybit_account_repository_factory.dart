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
