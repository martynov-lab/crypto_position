import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// Gate v4 public futures market data (`settle=usdt`). Responses are raw JSON
/// arrays/objects (no envelope).
class GateMarketData implements MarketDataProvider {
  final RestClient _client;

  GateMarketData({String baseUrl = 'https://api.gateio.ws'})
    : _client = publicRestClient(baseUrl);

  @override
  ExchangeId get exchange => ExchangeId.gate;

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async {
    final rows = await _getList('/api/v4/futures/usdt/contracts');
    final result = <PerpInstrument>[];
    for (final row in rows) {
      if (row['type'] == 'inverse') continue;
      final name = row['name'] as String?; // e.g. BTC_USDT
      if (name == null) continue;
      final parts = name.split('_');
      if (parts.length < 2) continue;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.gate,
          symbol: name,
          base: parts[0],
          quote: parts[1],
        ),
      );
    }
    return result;
  }

  @override
  Future<Quote> fetchQuote(String symbol) async {
    final rows = await _getList(
      '/api/v4/futures/usdt/tickers',
      {'contract': symbol},
    );
    if (rows.isEmpty) throw StateError('Gate: no ticker for $symbol');
    final row = rows.first;
    final last = asDouble(row['last']) ?? asDouble(row['mark_price']) ?? 0;
    return Quote(bid: last, ask: last, last: last);
  }

  @override
  Future<FundingInfo> fetchFunding(String symbol) async {
    final row = await _getMap('/api/v4/futures/usdt/contracts/$symbol');
    final intervalSec = asDouble(row['funding_interval']);
    final nextApplySec = asInt(row['funding_next_apply']);
    return FundingInfo(
      rate: asDouble(row['funding_rate']) ?? 0,
      intervalHours: intervalSec != null ? intervalSec / 3600 : 8,
      nextFundingMs: nextApplySec != null ? nextApplySec * 1000 : null,
    );
  }

  Future<List<Map<String, Object?>>> _getList(
    String path, [
    Map<String, Object?>? query,
  ]) async {
    final response = await _client.get<List<Object?>>(path, queryParams: query);
    return response.fold(
      (data) => data.cast<Map<String, Object?>>(),
      (error) => throw error,
    );
  }

  Future<Map<String, Object?>> _getMap(String path) async {
    final response = await _client.get<Map<String, Object?>>(path);
    return response.fold((data) => data, (error) => throw error);
  }
}
