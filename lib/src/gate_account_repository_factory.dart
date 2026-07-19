import 'package:crypto_position/src/gate_account_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gate/gate.dart';
import 'package:network/network.dart';

/// Builds the Gate account session graph once API keys are available.
///
/// Keys live in secure storage and are loaded asynchronously, so the
/// session cannot be provided directly at app start.
class GateAccountRepositoryFactory {
  final GateConfig _config;

  const GateAccountRepositoryFactory(this._config);

  GateAccountSession create({
    required String apiKey,
    required String apiSecret,
  }) {
    final dio = createSharedHttpClient()
      ..interceptors.addAll([
        // BaseUrl must be set before the auth interceptor signs the request.
        BaseUrlDioInterceptor(getHost: () => Uri.parse(_config.baseRestUrl)),
        GateAuthInterceptor(apiKey: apiKey, apiSecret: apiSecret),
        if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
      ]);

    // One connection, one protocol instance: it signs the private positions
    // subscription and leaves the public ticker subscriptions unsigned.
    final protocol = GateWsProtocol(apiKey: apiKey, apiSecret: apiSecret);

    final wsService = WsService(protocol);
    final positionSubscriber = PositionSubscriber(wsService);
    final tickerSubscriptions = TickerSubscriptions(wsService);
    // No authMessageFactory: Gate authenticates per subscription, so the socket
    // is considered ready as soon as it opens.
    final wsManager = WsManager(
      getUri: () => Uri.parse(_config.baseWsUrl),
      wsService: wsService,
      protocol: protocol,
    );

    final restClient = RestClient(dio);

    return GateAccountSession(
      repository: GateAccountRepository(
        gateAccountApi: GateAccountApi(restClient),
        positionSubscriber: positionSubscriber,
        tickerSubscriptions: tickerSubscriptions,
      ),
      tradeExecutor: GateTradeExecutor(restClient),
      wsManager: wsManager,
      protocol: protocol,
      wsService: wsService,
    );
  }
}
