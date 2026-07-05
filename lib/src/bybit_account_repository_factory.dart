import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';

/// Builds the Bybit account session graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// session cannot be provided directly at app start.
class BybitAccountRepositoryFactory {
  final BybitConfig _config;

  const BybitAccountRepositoryFactory(this._config);

  BybitAccountSession create({
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
        if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
      ]);

    final wsService = WsService();
    final walletSubscriber = WalletSubscriber(wsService);
    final wsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      authMessageFactory: () =>
          bybitWsAuthMessage(apiKey: apiKey, apiSecret: apiSecret),
      wsService: wsService,
    );

    return BybitAccountSession(
      repository: BybitAccountRepository(
        bybitAccountApi: BybitAccountApi(RestClient(dio)),
        walletSubscriber: walletSubscriber,
      ),
      wsManager: wsManager,
      wsService: wsService,
    );
  }
}
