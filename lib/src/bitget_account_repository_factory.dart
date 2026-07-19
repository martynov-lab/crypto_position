import 'package:bitget/bitget.dart';
import 'package:crypto_position/src/bitget_account_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';

/// Builds the Bitget account session graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// session cannot be provided directly at app start.
class BitgetAccountRepositoryFactory {
  final BitgetConfig _config;

  const BitgetAccountRepositoryFactory(this._config);

  BitgetAccountSession create({
    required String apiKey,
    required String apiSecret,
    required String passphrase,
  }) {
    final dio = createSharedHttpClient()
      ..interceptors.addAll([
        // BaseUrl must be set before the auth interceptor signs the request.
        BaseUrlDioInterceptor(getHost: () => Uri.parse(_config.baseRestUrl)),
        BitgetAuthInterceptor(
          apiKey: apiKey,
          apiSecret: apiSecret,
          passphrase: passphrase,
        ),
        if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
      ]);

    const protocol = BitgetWsProtocol();

    final wsService = WsService(protocol);
    final accountSubscriber = AccountSubscriber(wsService);
    final positionSubscriber = PositionSubscriber(wsService);
    final wsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      authMessageFactory: () => bitgetWsLoginMessage(
        apiKey: apiKey,
        apiSecret: apiSecret,
        passphrase: passphrase,
      ),
      wsService: wsService,
      protocol: protocol,
    );

    // Public stream (no auth): per-symbol ticker topics for live PnL.
    final publicWsService = WsService(protocol);
    final tickerSubscriptions = TickerSubscriptions(publicWsService);
    final publicWsManager = WsManager(
      getUri: () => Uri.parse(_config.basePublicWsUrl),
      wsService: publicWsService,
      protocol: protocol,
    );

    final restClient = RestClient(dio);

    return BitgetAccountSession(
      repository: BitgetAccountRepository(
        bitgetAccountApi: BitgetAccountApi(restClient),
        accountSubscriber: accountSubscriber,
        positionSubscriber: positionSubscriber,
        tickerSubscriptions: tickerSubscriptions,
      ),
      tradeExecutor: BitgetTradeExecutor(restClient),
      wsManager: wsManager,
      wsService: wsService,
      publicWsManager: publicWsManager,
      publicWsService: publicWsService,
    );
  }
}
