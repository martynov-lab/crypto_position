import 'dart:convert';
import 'dart:typed_data';

import 'package:bybit/bybit.dart';
import 'package:dio/dio.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

/// Routes responses by request path and records every request made.
class _RoutingAdapter implements HttpClientAdapter {
  final Map<String, Object?> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  _RoutingAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds an executor whose position list reports [positionIdxs] (hedge mode
/// when any is non-zero) and whose order endpoint always succeeds.
(BybitTradeExecutor, _RoutingAdapter) _executor(List<int> positionIdxs) {
  final adapter = _RoutingAdapter((options) {
    if (options.path.contains('/v5/position/list')) {
      return {
        'retCode': 0,
        'result': {
          'list': [
            for (final idx in positionIdxs) {'positionIdx': idx},
          ],
        },
      };
    }
    return {
      'retCode': 0,
      'result': {'orderId': 'abc'},
    };
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..httpClientAdapter = adapter;
  return (BybitTradeExecutor(RestClient(dio)), adapter);
}

/// The `positionIdx` sent on the order-create request.
int _sentPositionIdx(_RoutingAdapter adapter) {
  final create = adapter.requests
      .firstWhere((r) => r.path.contains('/v5/order/create'));
  return (jsonDecode(create.data as String) as Map)['positionIdx'] as int;
}

Future<int> _idxFor(
  List<int> positionIdxs, {
  required OrderSide side,
  bool reduceOnly = false,
}) async {
  final (executor, adapter) = _executor(positionIdxs);
  await executor.placeLimitOrder(
    symbol: 'BTCUSDT',
    side: side,
    qty: 1,
    price: 100,
    reduceOnly: reduceOnly,
  );
  return _sentPositionIdx(adapter);
}

void main() {
  group('BybitTradeExecutor positionIdx', () {
    test('one-way mode always sends 0', () async {
      expect(await _idxFor([0], side: OrderSide.buy), 0);
      expect(await _idxFor([0], side: OrderSide.sell), 0);
    });

    test('hedge mode: opening orders address the side they trade', () async {
      // Buy opens the long (1); sell opens the short (2).
      expect(await _idxFor([1, 2], side: OrderSide.buy), 1);
      expect(await _idxFor([1, 2], side: OrderSide.sell), 2);
    });

    test('hedge mode: reduce-only orders address the opposite side', () async {
      // Selling reduce-only closes the long (1); buying closes the short (2).
      expect(
        await _idxFor([1, 2], side: OrderSide.sell, reduceOnly: true),
        1,
      );
      expect(
        await _idxFor([1, 2], side: OrderSide.buy, reduceOnly: true),
        2,
      );
    });

    test('position mode is probed once and cached per symbol', () async {
      final (executor, adapter) = _executor([1, 2]);
      for (var i = 0; i < 3; i++) {
        await executor.placeLimitOrder(
          symbol: 'BTCUSDT',
          side: OrderSide.buy,
          qty: 1,
          price: 100,
        );
      }
      final probes = adapter.requests
          .where((r) => r.path.contains('/v5/position/list'))
          .length;
      expect(probes, 1);
    });
  });
}
