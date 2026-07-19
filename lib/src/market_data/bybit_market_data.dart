import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// Bybit v5 public market data (`category=linear`).
class BybitMarketData implements MarketDataProvider {
  final RestClient _client;

  /// Funding interval per symbol (hours), harvested from instruments-info so
  /// [fetchFunding] doesn't need a second call.
  final _intervalHours = <String, double>{};

  BybitMarketData({String baseUrl = 'https://api.bybit.com'})
    : _client = publicRestClient(baseUrl);

  @override
  ExchangeId get exchange => ExchangeId.bybit;

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/market/instruments-info',
      queryParams: {'category': 'linear'},
    );
    return response.fold(
      (data) {
        final list = _rows(data);
        final result = <PerpInstrument>[];
        for (final row in list) {
          if (row['contractType'] != 'LinearPerpetual') continue;
          if (row['status'] != 'Trading') continue;
          final symbol = row['symbol'] as String?;
          final base = row['baseCoin'] as String?;
          final quote = row['quoteCoin'] as String?;
          if (symbol == null || base == null || quote == null) continue;
          final minutes = asDouble(row['fundingInterval']);
          if (minutes != null) _intervalHours[symbol] = minutes / 60;
          final lot = row['lotSizeFilter'] as Map<String, Object?>?;
          final price = row['priceFilter'] as Map<String, Object?>?;
          result.add(
            PerpInstrument(
              exchange: ExchangeId.bybit,
              symbol: symbol,
              base: base,
              quote: quote,
              qtyStep: asDouble(lot?['qtyStep']),
              minQty: asDouble(lot?['minOrderQty']),
              tickSize: asDouble(price?['tickSize']),
              contractSize: 1,
            ),
          );
        }
        return result;
      },
      (error) => throw error,
    );
  }

  @override
  Future<Quote> fetchQuote(String symbol) async {
    final row = await _ticker(symbol);
    final last = asDouble(row['lastPrice']) ?? 0;
    return Quote(
      bid: asDouble(row['bid1Price']) ?? last,
      ask: asDouble(row['ask1Price']) ?? last,
      last: last,
    );
  }

  @override
  Future<FundingInfo> fetchFunding(String symbol) async {
    final row = await _ticker(symbol);
    return FundingInfo(
      rate: asDouble(row['fundingRate']) ?? 0,
      intervalHours: _intervalHours[symbol] ?? 8,
      nextFundingMs: asInt(row['nextFundingTime']),
    );
  }

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/market/orderbook',
      queryParams: {'category': 'linear', 'symbol': symbol, 'limit': depth},
    );
    return response.fold(
      (data) {
        final code = asInt(data['retCode']);
        if (code != null && code != 0) {
          throw StateError('Bybit error $code: ${data['retMsg']}');
        }
        final result = data['result'] as Map<String, Object?>?;
        return OrderBook(
          bids: _levels(result?['b']),
          asks: _levels(result?['a']),
        );
      },
      (error) => throw error,
    );
  }

  /// Parses Bybit's `[[price, size], ...]` book side into [BookLevel]s.
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

  Future<Map<String, Object?>> _ticker(String symbol) async {
    final response = await _client.get<Map<String, Object?>>(
      '/v5/market/tickers',
      queryParams: {'category': 'linear', 'symbol': symbol},
    );
    return response.fold(
      (data) {
        final list = _rows(data);
        if (list.isEmpty) throw StateError('Bybit: no ticker for $symbol');
        return list.first;
      },
      (error) => throw error,
    );
  }

  /// Unwraps `result.list`, raising on a non-zero `retCode`.
  static List<Map<String, Object?>> _rows(Map<String, Object?> data) {
    final code = asInt(data['retCode']);
    if (code != null && code != 0) {
      throw StateError('Bybit error $code: ${data['retMsg']}');
    }
    final result = data['result'] as Map<String, Object?>?;
    final list = result?['list'] as List?;
    return list?.cast<Map<String, Object?>>() ?? const [];
  }
}
