import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/closed_pnl_dto.dart';
import 'dto/wallet_balance_dto.dart';

class BybitAccountApi {
  static const _maxRangeMs = 7 * 24 * 60 * 60 * 1000;

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
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
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

  Future<Result<List<ClosedPnlDto>, Object>> fetchClosedPnl({
    required String category,
    String? symbol,
    int? startTime,
    int? endTime,
  }) async {
    if (startTime == null || endTime == null) {
      return _fetchChunk(
        category: category,
        symbol: symbol,
        startTime: startTime ?? 0,
        endTime: endTime ?? DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Bybit limits the range of one request to 7 days.
    final items = <ClosedPnlDto>[];
    var chunkStart = startTime;
    while (chunkStart < endTime) {
      var chunkEnd = chunkStart + _maxRangeMs;
      if (chunkEnd > endTime) chunkEnd = endTime;

      final chunk = await _fetchChunk(
        category: category,
        symbol: symbol,
        startTime: chunkStart,
        endTime: chunkEnd,
      );
      switch (chunk) {
        case Ok(:final value):
          items.addAll(value);
        case Err(:final error):
          return Err(error);
      }

      chunkStart = chunkEnd;
    }

    return Ok(items);
  }

  Future<Result<List<ClosedPnlDto>, Object>> _fetchChunk({
    required String category,
    String? symbol,
    required int startTime,
    required int endTime,
  }) async {
    final items = <ClosedPnlDto>[];
    String? cursor;

    do {
      final response = await _client.get<Map<String, Object?>>(
        '/v5/position/closed-pnl',
        queryParams: {
          'category': category,
          'limit': 100,
          'symbol': ?symbol,
          'startTime': startTime,
          'endTime': endTime,
          'cursor': ?cursor,
        },
      );

      final page = response.fold<Result<(List<ClosedPnlDto>, String?), Object>>(
        (data) {
          final envelopeError = _envelopeError(data);
          if (envelopeError != null) return Err(envelopeError);
          try {
            final result = data['result'] as Map<String, Object?>;
            final list = result['list'] as List<Object?>? ?? const [];
            final nextCursor = result['nextPageCursor'] as String?;
            return Ok((
              list
                  .map((e) =>
                      ClosedPnlDto.fromJson(e! as Map<String, Object?>))
                  .toList(),
              // The API returns the cursor URL-encoded; decode it so it is
              // encoded exactly once when sent back as a query parameter.
              (nextCursor != null && nextCursor.isNotEmpty)
                  ? Uri.decodeComponent(nextCursor)
                  : null,
            ));
          } on Object catch (error) {
            return Err(error);
          }
        },
        (error) => Err(error),
      );

      switch (page) {
        case Ok(value: (final pageItems, final nextCursor)):
          items.addAll(pageItems);
          cursor = nextCursor;
        case Err(:final error):
          return Err(error);
      }
    } while (cursor != null);

    return Ok(items);
  }

  /// Bybit wraps errors in an HTTP 200 envelope; `retCode != 0` is a failure.
  static CustomBackendException? _envelopeError(Map<String, Object?> data) {
    final retCode = data['retCode'];
    if (retCode is int && retCode != 0) {
      return CustomBackendException(
        message: data['retMsg'] as String? ?? 'Bybit error $retCode',
        error: data,
      );
    }
    return null;
  }
}
