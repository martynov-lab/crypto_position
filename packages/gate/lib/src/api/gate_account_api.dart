import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/balance_dto.dart';
import 'dto/contract_dto.dart';
import 'dto/position_close_dto.dart';
import 'dto/position_dto.dart';
import 'dto/total_balance_dto.dart';

/// Gate futures scoped to the USDT-settled market.
const _base = '/api/v4/futures/usdt';

class GateAccountApi {
  final RestClient _client;

  const GateAccountApi(this._client);

  /// The futures account (a single object, not a list). Gate signals errors via
  /// non-2xx HTTP status, which [RestClient] already surfaces as a `Result`
  /// error — there is no success envelope to unwrap.
  Future<Result<GateAccountDto, Object>> fetchBalance() async {
    final response = await _client.get<Map<String, Object?>>(
      '$_base/accounts',
    );

    return response.fold<Result<GateAccountDto, Object>>(
      (data) {
        try {
          return Ok(GateAccountDto.fromJson(data));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// Every wallet (spot, futures, margin, earn) summed and converted to USDT by
  /// Gate. Unlike [fetchBalance], which sees only the futures wallet, this is
  /// the account total the exchange's own UI shows.
  ///
  /// Fails with a permission error when the API key lacks wallet read access.
  Future<Result<TotalBalanceDto, Object>> fetchTotalBalance() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v4/wallet/total_balance',
      queryParams: {'currency': 'USDT'},
    );

    return response.fold<Result<TotalBalanceDto, Object>>(
      (data) {
        try {
          return Ok(TotalBalanceDto.fromJson(data));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// Public contract specs. One call covers every contract, so the repository
  /// reads the whole list rather than one request per open position.
  Future<Result<List<ContractDto>, Object>> fetchContracts() async {
    final response = await _client.get<List<Object?>>('$_base/contracts');

    return response.fold<Result<List<ContractDto>, Object>>(
      (data) {
        try {
          return Ok(
            data
                .map((e) => ContractDto.fromJson(e! as Map<String, Object?>))
                .toList(),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  Future<Result<List<PositionDto>, Object>> fetchPositions() async {
    final response = await _client.get<List<Object?>>('$_base/positions');

    return response.fold<Result<List<PositionDto>, Object>>(
      (data) {
        try {
          return Ok(
            data
                .map((e) => PositionDto.fromJson(e! as Map<String, Object?>))
                .toList(),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// Closed positions (realized-PnL history). [from]/[to] bound the close time
  /// in **seconds** since epoch; Gate caps [limit] at 1000.
  Future<Result<List<PositionCloseDto>, Object>> fetchPositionClose({
    int? from,
    int? to,
    int limit = 100,
  }) async {
    final response = await _client.get<List<Object?>>(
      '$_base/position_close',
      queryParams: {
        'from': ?from?.toString(),
        'to': ?to?.toString(),
        'limit': limit.toString(),
      },
    );

    return response.fold<Result<List<PositionCloseDto>, Object>>(
      (data) {
        try {
          return Ok(
            data
                .map((e) =>
                    PositionCloseDto.fromJson(e! as Map<String, Object?>))
                .toList(),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }
}
