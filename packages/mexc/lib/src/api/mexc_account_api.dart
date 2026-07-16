import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/balance_dto.dart';
import 'dto/contract_detail_dto.dart';
import 'dto/funding_rate_dto.dart';
import 'dto/history_position_dto.dart';
import 'dto/position_dto.dart';
import 'dto/ticker_dto.dart';

class MexcAccountApi {
  final RestClient _client;

  const MexcAccountApi(this._client);

  Future<Result<MexcBalanceDto, Object>> fetchBalance() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/private/account/assets',
    );
    return response.fold<Result<MexcBalanceDto, Object>>(
      (data) => _parse(
        data,
        (list) => MexcBalanceDto(
          list
              .map((e) => AssetDto.fromJson(e! as Map<String, Object?>))
              .toList(),
        ),
      ),
      (error) => Err(error),
    );
  }

  Future<Result<List<PositionDto>, Object>> fetchPositions() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/private/position/open_positions',
    );
    return response.fold<Result<List<PositionDto>, Object>>(
      (data) => _parse(
        data,
        (list) => list
            .map((e) => PositionDto.fromJson(e! as Map<String, Object?>))
            .toList(),
      ),
      (error) => Err(error),
    );
  }

  /// Closed positions (realized-PnL history), most recent first. MEXC pages by
  /// [pageNum]/[pageSize] rather than a time range, so the caller filters by
  /// close time client-side.
  Future<Result<List<HistoryPositionDto>, Object>> fetchHistoryPositions({
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/private/position/list/history_positions',
      queryParams: {
        'page_num': pageNum.toString(),
        'page_size': pageSize.toString(),
      },
    );
    return response.fold<Result<List<HistoryPositionDto>, Object>>(
      (data) => _parse(
        data,
        (list) => list
            .map((e) => HistoryPositionDto.fromJson(e! as Map<String, Object?>))
            .toList(),
      ),
      (error) => Err(error),
    );
  }

  /// Public: the funding schedule for one contract, whose `nextSettleTime` the
  /// ticker does not carry. Unlike the other endpoints MEXC returns a single
  /// object here rather than a list, so it cannot use [_parse].
  Future<Result<FundingRateDto, Object>> fetchFundingRate(String symbol) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/contract/funding_rate/$symbol',
    );
    return response.fold<Result<FundingRateDto, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final object = data['data'] as Map<String, Object?>? ?? const {};
          return Ok(FundingRateDto.fromJson(object));
        } on Object catch (error) {
          return Err(error);
        }
      },
      (error) => Err(error),
    );
  }

  /// Public: contract specs, used for the `contractSize` multiplier.
  Future<Result<List<ContractDetailDto>, Object>> fetchContractDetail() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/contract/detail',
    );
    return response.fold<Result<List<ContractDetailDto>, Object>>(
      (data) => _parse(
        data,
        (list) => list
            .map((e) => ContractDetailDto.fromJson(e! as Map<String, Object?>))
            .toList(),
      ),
      (error) => Err(error),
    );
  }

  /// Public: every contract's ticker (fair/mark price), used to seed live PnL.
  Future<Result<List<TickerDto>, Object>> fetchTickers() async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v1/contract/ticker',
    );
    return response.fold<Result<List<TickerDto>, Object>>(
      (data) => _parse(
        data,
        (list) => list
            .map((e) => TickerDto.fromJson(e! as Map<String, Object?>))
            .toList(),
      ),
      (error) => Err(error),
    );
  }

  /// Unwraps MEXC's `{success, code, data}` envelope: `success != true`
  /// (or `code != 0`) is a failure. [build] maps the `data` array.
  static Result<T, Object> _parse<T>(
    Map<String, Object?> body,
    T Function(List<Object?> list) build,
  ) {
    final envelopeError = _envelopeError(body);
    if (envelopeError != null) return Err(envelopeError);
    try {
      final list = body['data'] as List<Object?>? ?? const [];
      return Ok(build(list));
    } on Object catch (error) {
      return Err(error);
    }
  }

  static CustomBackendException? _envelopeError(Map<String, Object?> body) {
    final success = body['success'];
    final code = body['code'];
    if (success == false || (code is num && code != 0)) {
      return CustomBackendException(
        message: body['message'] as String? ?? 'MEXC error $code',
        error: body,
      );
    }
    return null;
  }
}
