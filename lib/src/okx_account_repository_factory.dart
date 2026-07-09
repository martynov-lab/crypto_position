import 'package:crypto_position/src/okx_account_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:okx/okx.dart';

/// Builds the OKX account session graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// session cannot be provided directly at app start.
class OkxAccountRepositoryFactory {
  final OkxConfig _config;

  const OkxAccountRepositoryFactory(this._config);

  OkxAccountSession create({
    required String apiKey,
    required String apiSecret,
    required String passphrase,
  }) {
    final clock = OkxClock();
    final dio = createSharedHttpClient()
      ..interceptors.addAll([
        // BaseUrl must be set before the auth interceptor signs the request.
        BaseUrlDioInterceptor(getHost: () => Uri.parse(_config.baseRestUrl)),
        OkxAuthInterceptor(
          apiKey: apiKey,
          apiSecret: apiSecret,
          passphrase: passphrase,
          clock: clock,
          demoTrading: _config.demoTrading,
        ),
        if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
      ]);

    const protocol = OkxWsProtocol();

    final wsService = WsService(protocol);
    final accountSubscriber = AccountSubscriber(wsService);
    final positionSubscriber = PositionSubscriber(wsService);
    final wsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      authMessageFactory: () => okxWsLoginMessage(
        apiKey: apiKey,
        apiSecret: apiSecret,
        passphrase: passphrase,
        // Corrected to server time for the same reason as REST (error 50102).
        timestamp: clock.nowMs() ~/ 1000,
      ),
      wsService: wsService,
      protocol: protocol,
    );

    // Public stream (no auth): per-instrument mark-price topics for live PnL.
    final publicWsService = WsService(protocol);
    final markPriceSubscriptions = MarkPriceSubscriptions(publicWsService);
    final publicWsManager = WsManager(
      getUri: () => Uri.parse(_config.basePublicWsUrl),
      wsService: publicWsService,
      protocol: protocol,
    );

    return OkxAccountSession(
      repository: OkxAccountRepository(
        okxAccountApi: OkxAccountApi(RestClient(dio)),
        clock: clock,
        accountSubscriber: accountSubscriber,
        positionSubscriber: positionSubscriber,
        markPriceSubscriptions: markPriceSubscriptions,
      ),
      wsManager: wsManager,
      wsService: wsService,
      publicWsManager: publicWsManager,
      publicWsService: publicWsService,
    );
  }
}
