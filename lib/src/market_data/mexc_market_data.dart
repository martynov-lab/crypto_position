import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// MEXC contract v1 public market data (USDT perpetuals, `BASE_USDT`).
class MexcMarketData implements MarketDataProvider {
  final RestClient _client;

  MexcMarketData({String baseUrl = 'https://contract.mexc.com'})
    : _client = publicRestClient(baseUrl);

  @override
  ExchangeId get exchange => ExchangeId.mexc;

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async {
    final rows = await _getList('/api/v1/contract/detail');
    final result = <PerpInstrument>[];
    for (final row in rows) {
      final quote = row['quoteCoin'] as String?;
      if (quote != 'USDT') continue;
      final symbol = row['symbol'] as String?; // BTC_USDT
      final base = row['baseCoin'] as String?;
      if (symbol == null || base == null) continue;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.mexc,
          symbol: symbol,
          base: base,
          quote: quote!,
        ),
      );
    }
    return result;
  }

  @override
  Future<Quote> fetchQuote(String symbol) async {
    final row = await _getMap('/api/v1/contract/ticker', {'symbol': symbol});
    final last = asDouble(row['lastPrice']) ?? 0;
    return Quote(
      bid: asDouble(row['bid1']) ?? last,
      ask: asDouble(row['ask1']) ?? last,
      last: last,
    );
  }

  @override
  Future<FundingInfo> fetchFunding(String symbol) async {
    final row = await _getMap('/api/v1/contract/funding_rate/$symbol');
    final cycleHours = asDouble(row['collectCycle']);
    return FundingInfo(
      rate: asDouble(row['fundingRate']) ?? 0,
      intervalHours: cycleHours ?? 8,
      nextFundingMs: asInt(row['nextSettleTime']),
    );
  }

  Future<List<Map<String, Object?>>> _getList(String path) async {
    final response = await _client.get<Map<String, Object?>>(path);
    return response.fold(
      (data) {
        _check(data);
        final list = data['data'] as List?;
        return list?.cast<Map<String, Object?>>() ?? const [];
      },
      (error) => throw error,
    );
  }

  Future<Map<String, Object?>> _getMap(
    String path, [
    Map<String, Object?>? query,
  ]) async {
    final response =
        await _client.get<Map<String, Object?>>(path, queryParams: query);
    return response.fold(
      (data) {
        _check(data);
        return (data['data'] as Map<String, Object?>?) ?? const {};
      },
      (error) => throw error,
    );
  }

  static void _check(Map<String, Object?> data) {
    if (data['success'] == false) {
      throw StateError('MEXC error ${data['code']}: ${data['message']}');
    }
  }
}
