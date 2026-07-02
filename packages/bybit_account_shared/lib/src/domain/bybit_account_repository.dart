import 'package:core_shared/core_shared.dart';

import '../api/bybit_account_api.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import 'models/wallet_balance_model.dart';

class BybitAccountRepository {
  final BybitAccountApi _api;

  const BybitAccountRepository({
    required BybitAccountApi bybitAccountApi,
  }) : _api = bybitAccountApi;

  Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final result = await _api.fetchWalletBalance(accountType: accountType);

    return result.map((dto) => dto.toModel());
  }
}
