import 'package:core/core.dart';
import 'package:network/network.dart';

import 'dto/closed_pnl_dto.dart';
import 'dto/position_dto.dart';
import 'dto/transaction_log_dto.dart';
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

  Future<Result<List<PositionDto>, Object>> fetchPositions({
    String category = 'linear',
    String settleCoin = 'USDT',
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/position/list',
      queryParams: {
        'category': category,
        'settleCoin': settleCoin,
        'limit': 200,
      },
    );

    return response.fold<Result<List<PositionDto>, Object>>(
      (data) {
        final envelopeError = _envelopeError(data);
        if (envelopeError != null) return Err(envelopeError);
        try {
          final result = data['result'] as Map<String, Object?>;
          final list = result['list'] as List<Object?>? ?? const [];
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

  /// Trading-fee (`TRADE`) and funding (`SETTLEMENT`) entries between
  /// [startTime] and [endTime], epoch ms. Bybit caps one request at 7 days, so
  /// longer ranges are walked in chunks like [fetchClosedPnl] does.
  ///
  /// The log is account-wide; callers filter by symbol themselves, because one
  /// request covers every position and is cheaper than one request per symbol.
  Future<Result<List<TransactionLogDto>, Object>> fetchTransactionLog({
    required int startTime,
    required int endTime,
    String accountType = 'UNIFIED',
    String category = 'linear',
  }) async {
    final items = <TransactionLogDto>[];
    var chunkStart = startTime;
    while (chunkStart < endTime) {
      var chunkEnd = chunkStart + _maxRangeMs;
      if (chunkEnd > endTime) chunkEnd = endTime;

      final chunk = await _fetchTransactionLogChunk(
        accountType: accountType,
        category: category,
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

  Future<Result<List<TransactionLogDto>, Object>> _fetchTransactionLogChunk({
    required String accountType,
    required String category,
    required int startTime,
    required int endTime,
  }) async {
    final items = <TransactionLogDto>[];
    String? cursor;

    do {
      final response = await _client.get<Map<String, Object?>>(
        '/v5/account/transaction-log',
        queryParams: {
          'accountType': accountType,
          'category': category,
          // The transaction log caps the page size at 50, unlike closed-pnl.
          'limit': 50,
          'startTime': startTime,
          'endTime': endTime,
          'cursor': ?cursor,
        },
      );

      final page =
          response.fold<Result<(List<TransactionLogDto>, String?), Object>>(
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
                      TransactionLogDto.fromJson(e! as Map<String, Object?>))
                  .toList(),
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
