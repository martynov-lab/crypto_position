import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// MEXC contract v1 public market data (USDT perpetuals, `BASE_USDT`).
class MexcMarketData implements MarketDataProvider {
  final RestClient _client;

  /// Base units per contract (`contractSize`) per symbol, harvested from the
  /// contract detail list. MEXC books and order volumes are in contracts, so
  /// [fetchOrderBook] multiplies by this to report base units.
  final _contractSize = <String, double>{};

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
      final contractSize = asDouble(row['contractSize']);
      if (contractSize != null && contractSize > 0) {
        _contractSize[symbol] = contractSize;
      }
      result.add(
        PerpInstrument(
          exchange: ExchangeId.mexc,
          symbol: symbol,
          base: base,
          quote: quote!,
          // MEXC sizes orders in contracts (integer vol steps).
          qtyStep: asDouble(row['volUnit']),
          minQty: asDouble(row['minVol']),
          tickSize: asDouble(row['priceUnit']),
          contractSize: contractSize,
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

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async {
    final data = await _getMap('/api/v1/contract/depth/$symbol', {
      'limit': depth,
    });
    // MEXC books are sized in contracts; convert to base units.
    final mult = _contractSize[symbol] ?? 1;
    return OrderBook(
      bids: _levels(data['bids'], mult),
      asks: _levels(data['asks'], mult),
    );
  }

  /// Parses MEXC's `[[price, vol, orderCount], ...]` book side, scaling
  /// contract volume to base units by [mult].
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
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final data = await _getMap('/api/v1/contract/kline/$symbol', {
      'interval': 'Min$intervalMinutes',
      'start': nowSec - intervalMinutes * 60 * limit,
      'end': nowSec,
    });
    // MEXC returns parallel arrays: {time: [...s], close: [...], ...}.
    final times = data['time'] as List? ?? const [];
    final closes = data['close'] as List? ?? const [];
    final out = <Candle>[];
    for (var i = 0; i < times.length && i < closes.length; i++) {
      final tsSec = asInt(times[i]);
      final close = asDouble(closes[i]);
      if (tsSec == null || close == null) continue;
      out.add(Candle(tsSec * 1000, close));
    }
    out.sort((a, b) => a.tsMs.compareTo(b.tsMs));
    return out;
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
