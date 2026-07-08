import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/balance_dto.dart';
import 'dto/position_dto.dart';

class OkxAccountApi {
  final RestClient _client;

  const OkxAccountApi(this._client);

  Future<Result<BalanceDto, Object>> fetchBalance() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v5/account/balance',
    );

    return response.fold<Result<BalanceDto, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final list = data['data'] as List<Object?>? ?? const [];
          if (list.isEmpty) {
            return const Ok(BalanceDto(totalEq: '0', details: []));
          }
          return Ok(BalanceDto.fromJson(list.first! as Map<String, Object?>));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  Future<Result<List<PositionDto>, Object>> fetchPositions({
    String instType = 'SWAP',
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v5/account/positions',
      queryParams: {'instType': instType},
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

  /// OKX wraps errors in an HTTP 200 envelope; `code != "0"` is a failure.
  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final code = data['code'];
    if (code is String && code != '0') {
      return CustomBackendException(
        message: data['msg'] as String? ?? 'OKX error $code',
        error: data,
      );
    }
    return null;
  }
}
