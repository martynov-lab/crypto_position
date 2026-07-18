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
          result.add(
            PerpInstrument(
              exchange: ExchangeId.bybit,
              symbol: symbol,
              base: base,
              quote: quote,
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
