import 'package:core_shared/core_shared.dart';

import '../api/bybit_account_api.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import '../api/wallet_subscriber.dart';
import 'models/closed_trade_model.dart';
import 'models/wallet_balance_model.dart';

class BybitAccountRepository {
  final BybitAccountApi _api;
  final WalletSubscriber? _walletSubscriber;

  const BybitAccountRepository({
    required BybitAccountApi bybitAccountApi,
    WalletSubscriber? walletSubscriber,
  })  : _api = bybitAccountApi,
        _walletSubscriber = walletSubscriber;

  Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final result = await _api.fetchWalletBalance(accountType: accountType);

    return result.map((dto) => dto.toModel());
  }

  Future<Result<List<ClosedTradeModel>, Object>> fetchClosedTrades({
    required String category,
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _api.fetchClosedPnl(
      category: category,
      symbol: symbol,
      startTime: startDate?.millisecondsSinceEpoch,
      endTime: endDate?.millisecondsSinceEpoch,
    );

    return result.map(
      (dtoList) => dtoList.map((dto) => dto.toModel()).toList(),
    );
  }

  /// Live wallet updates from the WebSocket stream.
  Stream<WalletBalanceModel> get walletUpdates {
    final subscriber = _walletSubscriber;
    if (subscriber == null) {
      throw StateError('BybitAccountRepository has no WalletSubscriber');
    }
    return subscriber.stream.map((dto) => dto.toModel());
  }
}
