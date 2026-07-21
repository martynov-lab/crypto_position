import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:okx/okx.dart';

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

/// Executor whose account reports [posMode] and whose order endpoint returns
/// [orderResponse] (defaulting to a success).
(OkxTradeExecutor, _RoutingAdapter) _executor(
  String posMode, {
  Map<String, Object?>? orderResponse,
}) {
  final adapter = _RoutingAdapter((options) {
    if (options.path.contains('/api/v5/account/config')) {
      return {
        'code': '0',
        'data': [
          {'posMode': posMode},
        ],
      };
    }
    return orderResponse ??
        {
          'code': '0',
          'data': [
            {'sCode': '0', 'ordId': 'abc'},
          ],
        };
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..httpClientAdapter = adapter;
  return (OkxTradeExecutor(RestClient(dio)), adapter);
}

Map<String, Object?> _orderBody(_RoutingAdapter adapter) {
  final order = adapter.requests
      .firstWhere((r) => r.path.contains('/api/v5/trade/order'));
  return jsonDecode(order.data as String) as Map<String, Object?>;
}

Future<Map<String, Object?>> _bodyFor(
  String posMode, {
  required OrderSide side,
  bool reduceOnly = false,
}) async {
  final (executor, adapter) = _executor(posMode);
  await executor.placeLimitOrder(
    symbol: 'LA-USDT-SWAP',
    side: side,
    qty: 1,
    price: 100,
    reduceOnly: reduceOnly,
  );
  return _orderBody(adapter);
}

void main() {
  group('OkxTradeExecutor posSide', () {
    test('net mode sends reduceOnly and no posSide', () async {
      final body = await _bodyFor('net_mode', side: OrderSide.buy);
      expect(body.containsKey('posSide'), isFalse);
      expect(body['reduceOnly'], isFalse);
    });

    test('hedge mode: opening orders address the side they trade', () async {
      expect(
        (await _bodyFor('long_short_mode', side: OrderSide.buy))['posSide'],
        'long',
      );
      expect(
        (await _bodyFor('long_short_mode', side: OrderSide.sell))['posSide'],
        'short',
      );
    });

    test('hedge mode: reduce-only orders address the opposite side', () async {
      final closeLong = await _bodyFor(
        'long_short_mode',
        side: OrderSide.sell,
        reduceOnly: true,
      );
      expect(closeLong['posSide'], 'long');

      final closeShort = await _bodyFor(
        'long_short_mode',
        side: OrderSide.buy,
        reduceOnly: true,
      );
      expect(closeShort['posSide'], 'short');
    });

    test('hedge mode omits reduceOnly, which OKX rejects there', () async {
      final body = await _bodyFor(
        'long_short_mode',
        side: OrderSide.sell,
        reduceOnly: true,
      );
      expect(body.containsKey('reduceOnly'), isFalse);
    });

    test('position mode is looked up once and cached', () async {
      final (executor, adapter) = _executor('long_short_mode');
      for (var i = 0; i < 3; i++) {
        await executor.placeLimitOrder(
          symbol: 'LA-USDT-SWAP',
          side: OrderSide.buy,
          qty: 1,
          price: 100,
        );
      }
      final lookups = adapter.requests
          .where((r) => r.path.contains('/api/v5/account/config'))
          .length;
      expect(lookups, 1);
    });
  });

  group('OkxTradeExecutor error reporting', () {
    test('surfaces the per-order sMsg behind "All operations failed"', () async {
      final (executor, _) = _executor(
        'net_mode',
        orderResponse: {
          'code': '1',
          'msg': 'All operations failed',
          'data': [
            {'sCode': '51000', 'sMsg': 'Parameter posSide error'},
          ],
        },
      );
      final result = await executor.placeLimitOrder(
        symbol: 'LA-USDT-SWAP',
        side: OrderSide.buy,
        qty: 1,
        price: 100,
      );

      expect(result, isA<Err<OrderAck, Object>>());
      final error = (result as Err<OrderAck, Object>).error;
      expect('$error', contains('Parameter posSide error'));
      expect('$error', isNot(contains('All operations failed')));
    });
  });
}
