import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// Bitget v2 public market data (`productType=USDT-FUTURES`).
class BitgetMarketData implements MarketDataProvider {
  static const _productType = 'USDT-FUTURES';

  final RestClient _client;

  /// Funding interval per symbol (hours), harvested from the contracts list.
  final _intervalHours = <String, double>{};

  BitgetMarketData({String baseUrl = 'https://api.bitget.com'})
    : _client = publicRestClient(baseUrl);

  @override
  ExchangeId get exchange => ExchangeId.bitget;

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async {
    final rows = await _get('/api/v2/mix/market/contracts', {
      'productType': _productType,
    });
    final result = <PerpInstrument>[];
    for (final row in rows) {
      final symbol = row['symbol'] as String?;
      final base = row['baseCoin'] as String?;
      final quote = row['quoteCoin'] as String?;
      if (symbol == null || base == null || quote == null) continue;
      final interval = asDouble(row['fundInterval']);
      if (interval != null) _intervalHours[symbol] = interval;
      // Bitget reports price precision as decimal places + an end step; derive
      // the absolute tick size from them (e.g. pricePlace 1, priceEndStep 5 =>
      // 0.5).
      final pricePlace = asInt(row['pricePlace']);
      final priceEndStep = asDouble(row['priceEndStep']);
      final tickSize = (pricePlace != null && priceEndStep != null)
          ? priceEndStep / _pow10(pricePlace)
          : null;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.bitget,
          symbol: symbol,
          base: base,
          quote: quote,
          qtyStep: asDouble(row['sizeMultiplier']),
          minQty: asDouble(row['minTradeNum']),
          tickSize: tickSize,
          contractSize: 1,
        ),
      );
    }
    return result;
  }

  @override
  Future<Quote> fetchQuote(String symbol) async {
    final rows = await _get('/api/v2/mix/market/ticker', {
      'symbol': symbol,
      'productType': _productType,
    });
    if (rows.isEmpty) throw StateError('Bitget: no ticker for $symbol');
    final row = rows.first;
    final last = asDouble(row['lastPr']) ?? 0;
    return Quote(
      bid: asDouble(row['bidPr']) ?? last,
      ask: asDouble(row['askPr']) ?? last,
      last: last,
    );
  }

  @override
  Future<FundingInfo> fetchFunding(String symbol) async {
    final rateRows = await _get('/api/v2/mix/market/current-fund-rate', {
      'symbol': symbol,
      'productType': _productType,
    });
    final timeRows = await _get('/api/v2/mix/market/funding-time', {
      'symbol': symbol,
      'productType': _productType,
    });
    final rate = rateRows.isEmpty
        ? 0.0
        : asDouble(rateRows.first['fundingRate']) ?? 0;
    final nextMs = timeRows.isEmpty ? null : asInt(timeRows.first['nextFundingTime']);
    final period = timeRows.isEmpty ? null : asDouble(timeRows.first['ratePeriod']);
    return FundingInfo(
      rate: rate,
      intervalHours: period ?? _intervalHours[symbol] ?? 8,
      nextFundingMs: nextMs,
    );
  }

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v2/mix/market/merge-depth',
      queryParams: {
        'symbol': symbol,
        'productType': _productType,
        'limit': '$depth',
      },
    );
    return response.fold(
      (data) {
        final code = data['code'];
        if (code is String && code != '00000') {
          throw StateError('Bitget error $code: ${data['msg']}');
        }
        final book = data['data'] as Map<String, Object?>?;
        return OrderBook(
          bids: _levels(book?['bids']),
          asks: _levels(book?['asks']),
        );
      },
      (error) => throw error,
    );
  }

  /// Parses Bitget's `[[price, size], ...]` book side into [BookLevel]s.
  static List<BookLevel> _levels(Object? raw) {
    if (raw is! List) return const [];
    final out = <BookLevel>[];
    for (final row in raw) {
      if (row is! List || row.length < 2) continue;
      final price = asDouble(row[0]);
      final size = asDouble(row[1]);
      if (price == null || size == null) continue;
      out.add(BookLevel(price, size));
    }
    return out;
  }

  static double _pow10(int n) {
    var v = 1.0;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }

  Future<List<Map<String, Object?>>> _get(
    String path,
    Map<String, Object?> query,
  ) async {
    final response =
        await _client.get<Map<String, Object?>>(path, queryParams: query);
    return response.fold(
      (data) {
        final code = data['code'];
        if (code is String && code != '00000') {
          throw StateError('Bitget error $code: ${data['msg']}');
        }
        final list = data['data'] as List?;
        return list?.cast<Map<String, Object?>>() ?? const [];
      },
      (error) => throw error,
    );
  }
}
