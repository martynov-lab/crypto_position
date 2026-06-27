import 'dart:async';

import '../api/bybit_rest_client.dart';
import '../api/bybit_ws_client.dart';
import '../mapper/closed_trade_mapper.dart';
import '../mapper/wallet_balance_mapper.dart';
import 'models/closed_trade.dart';
import 'models/wallet_balance.dart';

class BybitRepository {
  final BybitRestClient _restClient;
  final BybitWsClient _wsClient;
  final WalletBalanceMapper _walletMapper;
  final ClosedTradeMapper _tradeMapper;

  BybitRepository({
    required BybitRestClient restClient,
    required BybitWsClient wsClient,
    WalletBalanceMapper? walletMapper,
    ClosedTradeMapper? tradeMapper,
  }) : _restClient = restClient,
       _wsClient = wsClient,
       _walletMapper = walletMapper ?? WalletBalanceMapper(),
       _tradeMapper = tradeMapper ?? ClosedTradeMapper();

  Future<WalletBalance> fetchBalance({String accountType = 'UNIFIED'}) async {
    final dto = await _restClient.getWalletBalance(accountType: accountType);
    return _walletMapper.fromDto(dto);
  }

  Stream<WalletBalance> get walletUpdates =>
      _wsClient.walletStream.map(_walletMapper.fromDto);

  Future<List<ClosedTrade>> fetchClosedTrades({
    String category = 'linear',
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dtoList = await _restClient.getAllClosedPnl(
      category: category,
      symbol: symbol,
      startTime: startDate?.millisecondsSinceEpoch,
      endTime: endDate?.millisecondsSinceEpoch,
    );
    return _tradeMapper.fromDtoList(dtoList);
  }

  void connectWs() => _wsClient.listen();

  void dispose() => _wsClient.close();
}
