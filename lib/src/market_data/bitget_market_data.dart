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
      result.add(
        PerpInstrument(
          exchange: ExchangeId.bitget,
          symbol: symbol,
          base: base,
          quote: quote,
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
