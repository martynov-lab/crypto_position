import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/public_rest.dart';
import 'package:network/network.dart';

/// Gate v4 public futures market data (`settle=usdt`). Responses are raw JSON
/// arrays/objects (no envelope).
class GateMarketData implements MarketDataProvider {
  final RestClient _client;

  /// Base units per contract (`quanto_multiplier`) per symbol, harvested from
  /// the contracts list. Gate books and order sizes are in whole contracts, so
  /// [fetchOrderBook] multiplies by this to report base units.
  final _multiplier = <String, double>{};

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
      final mult = asDouble(row['quanto_multiplier']);
      if (mult != null && mult > 0) _multiplier[name] = mult;
      result.add(
        PerpInstrument(
          exchange: ExchangeId.gate,
          symbol: name,
          base: parts[0],
          quote: parts[1],
          // Gate sizes orders in whole contracts.
          qtyStep: 1,
          minQty: asDouble(row['order_size_min']),
          tickSize: asDouble(row['order_price_round']),
          contractSize: mult,
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

  @override
  Future<OrderBook> fetchOrderBook(String symbol, {int depth = 50}) async {
    final response = await _client.get<Map<String, Object?>>(
      '/api/v4/futures/usdt/order_book',
      queryParams: {'contract': symbol, 'limit': depth},
    );
    return response.fold(
      (data) {
        // Gate books are sized in whole contracts; convert to base units.
        final mult = _multiplier[symbol] ?? 1;
        return OrderBook(
          bids: _levels(data['bids'], mult),
          asks: _levels(data['asks'], mult),
        );
      },
      (error) => throw error,
    );
  }

  /// Parses Gate's `[{p: price, s: size}, ...]` book side, scaling contract
  /// size to base units by [mult].
  static List<BookLevel> _levels(Object? raw, double mult) {
    if (raw is! List) return const [];
    final out = <BookLevel>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final price = asDouble(row['p']);
      final size = asDouble(row['s']);
      if (price == null || size == null) continue;
      out.add(BookLevel(price, size * mult));
    }
    return out;
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
