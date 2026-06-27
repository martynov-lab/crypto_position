import 'package:dio/dio.dart';

import '../dto/closed_pnl_dto.dart';
import '../dto/wallet_balance_dto.dart';

class BybitRestClient {
  final Dio _dio;

  BybitRestClient(this._dio);

  Future<WalletBalanceDto> getWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final response = await _dio.get(
      '/v5/account/wallet-balance',
      queryParameters: {'accountType': accountType},
    );

    final data = response.data as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    final list = result['list'] as List<dynamic>;
    if (list.isEmpty) {
      return WalletBalanceDto(
        accountType: accountType,
        totalEquity: '0',
        totalWalletBalance: '0',
        coins: [],
      );
    }
    return WalletBalanceDto.fromJson(list.first as Map<String, dynamic>);
  }

  Future<ClosedPnlPageDto> getClosedPnlPage({
    required String category,
    String? symbol,
    int? startTime,
    int? endTime,
    int limit = 100,
    String? cursor,
  }) async {
    final params = <String, dynamic>{
      'category': category,
      'limit': limit,
    };
    if (symbol != null) params['symbol'] = symbol;
    if (startTime != null) params['startTime'] = startTime;
    if (endTime != null) params['endTime'] = endTime;
    if (cursor != null) params['cursor'] = cursor;

    final response = await _dio.get(
      '/v5/position/closed-pnl',
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    final list = result['list'] as List<dynamic>? ?? [];
    final nextCursor = result['nextPageCursor'] as String?;

    return ClosedPnlPageDto(
      list: list
          .map((e) => ClosedPnlDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPageCursor:
          (nextCursor != null && nextCursor.isNotEmpty) ? nextCursor : null,
    );
  }

  static const _maxRangeMs = 7 * 24 * 60 * 60 * 1000;

  Future<List<ClosedPnlDto>> _fetchChunk({
    required String category,
    String? symbol,
    required int startTime,
    required int endTime,
  }) async {
    final allItems = <ClosedPnlDto>[];
    String? cursor;

    do {
      final page = await getClosedPnlPage(
        category: category,
        symbol: symbol,
        startTime: startTime,
        endTime: endTime,
        cursor: cursor,
      );
      allItems.addAll(page.list);
      cursor = page.nextPageCursor;
    } while (cursor != null);

    return allItems;
  }

  Future<List<ClosedPnlDto>> getAllClosedPnl({
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

    final allItems = <ClosedPnlDto>[];
    var chunkStart = startTime;

    while (chunkStart < endTime) {
      var chunkEnd = chunkStart + _maxRangeMs;
      if (chunkEnd > endTime) chunkEnd = endTime;

      final items = await _fetchChunk(
        category: category,
        symbol: symbol,
        startTime: chunkStart,
        endTime: chunkEnd,
      );
      allItems.addAll(items);

      chunkStart = chunkEnd;
    }

    return allItems;
  }
}
