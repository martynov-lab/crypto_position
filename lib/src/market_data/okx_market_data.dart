import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// OKX v5 public market data (linear USDT `SWAP`).
class OkxMarketData implements MarketDataProvider {
  final RestClient _client;

  /// Contract value in base units per symbol (`ctVal`), harvested from the
  /// instruments list. OKX books are sized in contracts, so [fetchOrderBook]
  /// multiplies by this to report base units.
  final _ctVal = <String, double>{};

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
      final ctVal = asDouble(row['ctVal']);
      if (ctVal != null) _ctVal[instId] = ctVal;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.okx,
          symbol: instId,
          base: parts[0],
          quote: parts[1],
          qtyStep: asDouble(row['lotSz']),
          minQty: asDouble(row['minSz']),
          tickSize: asDouble(row['tickSz']),
          contractSize: ctVal,
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

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async {
    final rows = await _get('/api/v5/market/books', {
      'instId': symbol,
      'sz': depth,
    });
    if (rows.isEmpty) return const OrderBook(bids: [], asks: []);
    final row = rows.first;
    // OKX books are sized in contracts; convert to base units via ctVal.
    final mult = _ctVal[symbol] ?? 1;
    return OrderBook(
      bids: _levels(row['bids'], mult),
      asks: _levels(row['asks'], mult),
    );
  }

  /// Parses OKX's `[[price, size, ...], ...]` book side, scaling size to base
  /// units by [mult].
  static List<BookLevel> _levels(Object? raw, double mult) {
    if (raw is! List) return const [];
    final out = <BookLevel>[];
    for (final row in raw) {
      if (row is! List || row.length < 2) continue;
      final price = asDouble(row[0]);
      final size = asDouble(row[1]);
      if (price == null || size == null) continue;
      out.add(BookLevel(price, size * mult));
    }
    return out;
  }

  @override
  Future<List<Candle>> fetchKlines(
    String symbol, {
    int intervalMinutes = 1,
    int limit = 60,
  }) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v5/market/candles',
      queryParams: {
        'instId': symbol,
        'bar': '${intervalMinutes}m',
        'limit': '$limit',
      },
    );
    return response.fold(
      (data) {
        final code = data['code'];
        if (code is String && code != '0') {
          throw StateError('OKX error $code: ${data['msg']}');
        }
        final rows = data['data'] as List? ?? const [];
        final out = <Candle>[];
        // Rows are [ts, open, high, low, close, ...].
        for (final row in rows) {
          if (row is! List || row.length < 5) continue;
          final ts = asInt(row[0]);
          final close = asDouble(row[4]);
          if (ts == null || close == null) continue;
          out.add(Candle(ts, close));
        }
        // OKX returns newest first.
        out.sort((a, b) => a.tsMs.compareTo(b.tsMs));
        return out;
      },
      (error) => throw error,
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
