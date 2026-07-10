import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/balance_dto.dart';
import 'dto/position_dto.dart';
import 'dto/position_history_dto.dart';

/// Bitget mix (futures) is scoped to USDT perpetuals; the single market means
/// these are constants rather than parameters.
const _productType = 'USDT-FUTURES';
const _marginCoin = 'USDT';

class BitgetAccountApi {
  final RestClient _client;

  const BitgetAccountApi(this._client);

  Future<Result<BitgetBalanceDto, Object>> fetchBalance() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v2/mix/account/accounts',
      queryParams: const {'productType': _productType},
    );

    return response.fold<Result<BitgetBalanceDto, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final list = data['data'] as List<Object?>? ?? const [];
          return Ok(
            BitgetBalanceDto(
              list
                  .map((e) => BitgetAccountDto.fromJson(e! as Map<String, Object?>))
                  .toList(),
            ),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  Future<Result<List<PositionDto>, Object>> fetchPositions() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v2/mix/position/all-position',
      queryParams: const {
        'productType': _productType,
        'marginCoin': _marginCoin,
      },
    );

    return response.fold<Result<List<PositionDto>, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final list = data['data'] as List<Object?>? ?? const [];
          return Ok(
            list
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

  /// Fetches closed positions (realized-PnL history). [startTime]/[endTime]
  /// bound the close time in milliseconds since epoch; Bitget caps [limit] at
  /// 100. The `data.list` array holds the entries.
  Future<Result<List<PositionHistoryDto>, Object>> fetchPositionsHistory({
    int? startTime,
    int? endTime,
    int limit = 100,
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v2/mix/position/history-position',
      queryParams: {
        'productType': _productType,
        'startTime': ?startTime?.toString(),
        'endTime': ?endTime?.toString(),
        'limit': limit.toString(),
      },
    );

    return response.fold<Result<List<PositionHistoryDto>, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final payload = data['data'] as Map<String, Object?>? ?? const {};
          final list = payload['list'] as List<Object?>? ?? const [];
          return Ok(
            list
                .map((e) =>
                    PositionHistoryDto.fromJson(e! as Map<String, Object?>))
                .toList(),
          );
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// Bitget wraps errors in an HTTP 200 envelope; `code != "00000"` is a
  /// failure.
  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final code = data['code'];
    if (code is String && code != '00000') {
      return CustomBackendException(
        message: data['msg'] as String? ?? 'Bitget error $code',
        error: data,
      );
    }
    return null;
  }
}
