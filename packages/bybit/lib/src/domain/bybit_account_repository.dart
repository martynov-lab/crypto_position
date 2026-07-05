import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../api/bybit_account_api.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import '../api/wallet_subscriber.dart';
import 'models/closed_trade_model.dart';
import 'models/wallet_balance_model.dart';

class BybitAccountRepository {
  final BybitAccountApi _api;
  final ValueNotifier<WalletBalanceModel?> _balance = ValueNotifier(null);

  StreamSubscription<void>? _walletSub;

  BybitAccountRepository({
    required BybitAccountApi bybitAccountApi,
    WalletSubscriber? walletSubscriber,
  }) : _api = bybitAccountApi {
    _walletSub = walletSubscriber?.stream.listen(
      (dto) => _balance.value = dto.toModel(),
    );
  }

  /// Current wallet balance: filled by [fetchWalletBalance] and kept
  /// up to date by the WebSocket wallet stream.
  ValueListenable<WalletBalanceModel?> get balance => _balance;

  Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final result = await _api.fetchWalletBalance(accountType: accountType);

    return result.map((dto) {
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
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

  void dispose() {
    _walletSub?.cancel();
    _balance.dispose();
  }
}
