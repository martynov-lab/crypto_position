import 'package:core_shared/core_shared.dart';
import 'package:network_shared/network_shared.dart';

import 'dto/wallet_balance_dto.dart';

class BybitAccountApi {
  final RestClient _client;

  const BybitAccountApi(this._client);

  Future<Result<WalletBalanceDto, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/account/wallet-balance',
      queryParams: {'accountType': accountType},
    );

    return response.fold<Result<WalletBalanceDto, Object>>(
      (data) {
        try {
          final result = data['result'] as Map<String, Object?>;
          final list = result['list'] as List<Object?>;
          if (list.isEmpty) {
            return Ok(
              WalletBalanceDto(
                accountType: accountType,
                totalEquity: '0',
                totalWalletBalance: '0',
                coins: const [],
              ),
            );
          }
          return Ok(
            WalletBalanceDto.fromJson(list.first! as Map<String, Object?>),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }
}
