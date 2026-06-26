import 'dart:async';

import '../api/bybit_rest_client.dart';
import '../api/bybit_ws_client.dart';
import 'models/wallet_balance.dart';

class BybitRepository {
  final BybitRestClient _restClient;
  final BybitWsClient _wsClient;

  BybitRepository({
    required String apiKey,
    required String apiSecret,
  })  : _restClient = BybitRestClient(apiKey: apiKey, apiSecret: apiSecret),
        _wsClient = BybitWsClient(apiKey: apiKey, apiSecret: apiSecret);

  Future<WalletBalance> fetchBalance({
    String accountType = 'UNIFIED',
  }) {
    return _restClient.getWalletBalance(accountType: accountType);
  }

  Stream<WalletBalance> get walletUpdates => _wsClient.walletStream;

  void connectWs() => _wsClient.connect();

  void dispose() => _wsClient.close();
}
