import 'package:crypto_position/src/mexc_account_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mexc/mexc.dart';
import 'package:network/network.dart';

/// Builds the MEXC account session graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// session cannot be provided directly at app start.
class MexcAccountRepositoryFactory {
  final MexcConfig _config;

  const MexcAccountRepositoryFactory(this._config);

  MexcAccountSession create({
    required String apiKey,
    required String apiSecret,
  }) {
    final dio = createSharedHttpClient()
      ..interceptors.addAll([
        // BaseUrl must be set before the auth interceptor signs the request.
        BaseUrlDioInterceptor(getHost: () => Uri.parse(_config.baseRestUrl)),
        MexcAuthInterceptor(apiKey: apiKey, apiSecret: apiSecret),
        if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
      ]);

    const protocol = MexcWsProtocol();

    // Private stream: logs in, then personal asset/position channels push.
    final wsService = WsService(protocol);
    final accountSubscriber = AccountSubscriber(wsService);
    final positionSubscriber = PositionSubscriber(wsService);
    final wsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      authMessageFactory: () =>
          mexcWsLoginMessage(apiKey: apiKey, apiSecret: apiSecret),
      wsService: wsService,
      protocol: protocol,
    );

    // Public stream (no auth): per-symbol ticker topics for live PnL.
    final publicWsService = WsService(protocol);
    final tickerSubscriptions = TickerSubscriptions(publicWsService);
    final publicWsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      wsService: publicWsService,
      protocol: protocol,
    );

    final restClient = RestClient(dio);

    return MexcAccountSession(
      repository: MexcAccountRepository(
        mexcAccountApi: MexcAccountApi(restClient),
        accountSubscriber: accountSubscriber,
        positionSubscriber: positionSubscriber,
        tickerSubscriptions: tickerSubscriptions,
      ),
      tradeExecutor: MexcTradeExecutor(restClient),
      wsManager: wsManager,
      wsService: wsService,
      publicWsManager: publicWsManager,
      publicWsService: publicWsService,
    );
  }
}
