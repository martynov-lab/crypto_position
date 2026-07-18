import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// OKX v5 public market data (linear USDT `SWAP`).
class OkxMarketData implements MarketDataProvider {
  final RestClient _client;

  OkxMarketData({String baseUrl = 'https://www.okx.com'})
    : _client = publicRestClient(baseUrl);

  @override
  ExchangeId get exchange => ExchangeId.okx;

  @override
  Future<List<PerpInstrument>> fetchPerpInstruments() async {
    final rows = await _get('/api/v5/public/instruments', {'instType': 'SWAP'});
    final result = <PerpInstrument>[];
    for (final row in rows) {
      if (row['settleCcy'] != 'USDT') continue;
      final instId = row['instId'] as String?;
      final uly = row['uly'] as String?; // e.g. BTC-USDT
      if (instId == null || uly == null) continue;
      final parts = uly.split('-');
      if (parts.length < 2) continue;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.okx,
          symbol: instId,
          base: parts[0],
          quote: parts[1],
        ),
      );
    }
    return result;
  }

  @override
  Future<Quote> fetchQuote(String symbol) async {
    final rows = await _get('/api/v5/market/ticker', {'instId': symbol});
    if (rows.isEmpty) throw StateError('OKX: no ticker for $symbol');
    final row = rows.first;
    final last = asDouble(row['last']) ?? 0;
    return Quote(
      bid: asDouble(row['bidPx']) ?? last,
      ask: asDouble(row['askPx']) ?? last,
      last: last,
    );
  }

  @override
  Future<FundingInfo> fetchFunding(String symbol) async {
    final rows = await _get('/api/v5/public/funding-rate', {'instId': symbol});
    if (rows.isEmpty) throw StateError('OKX: no funding for $symbol');
    final row = rows.first;
    final current = asInt(row['fundingTime']);
    final next = asInt(row['nextFundingTime']);
    final intervalHours = (current != null && next != null && next > current)
        ? (next - current) / 3600000
        : 8.0;
    return FundingInfo(
      rate: asDouble(row['fundingRate']) ?? 0,
      intervalHours: intervalHours,
      nextFundingMs: next,
    );
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
        if (code is String && code != '0') {
          throw StateError('OKX error $code: ${data['msg']}');
        }
        final list = data['data'] as List?;
        return list?.cast<Map<String, Object?>>() ?? const [];
      },
      (error) => throw error,
    );
  }
}
