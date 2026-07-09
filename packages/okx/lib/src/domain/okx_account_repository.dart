import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/account_subscriber.dart';
import '../api/dto/position_dto.dart';
import '../api/mappers/balance_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/mark_price_subscriptions.dart';
import '../api/okx_account_api.dart';
import '../api/position_subscriber.dart';
import '../service/okx_clock.dart';

class OkxAccountRepository implements ExchangeAccountRepository {
  final OkxAccountApi _api;
  final OkxClock _clock;
  final MarkPriceSubscriptions? _markPriceSubscriptions;
  final ValueNotifier<BalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<List<PositionModel>?> _positions = ValueNotifier(null);

  /// Open positions keyed by '$instId#$posSide'.
  final _positionsByKey = <String, PositionModel>{};
  final _markPriceSubs = <String, StreamSubscription<void>>{};

  StreamSubscription<void>? _accountSub;
  StreamSubscription<void>? _positionSub;

  OkxAccountRepository({
    required OkxAccountApi okxAccountApi,
    required OkxClock clock,
    AccountSubscriber? accountSubscriber,
    PositionSubscriber? positionSubscriber,
    MarkPriceSubscriptions? markPriceSubscriptions,
  })  : _api = okxAccountApi,
        _clock = clock,
        _markPriceSubscriptions = markPriceSubscriptions {
    _accountSub = accountSubscriber?.stream.listen(
      (dto) => _balance.value = dto.toModel(),
    );
    _positionSub = positionSubscriber?.stream.listen(_onPositionEvent);
  }

  /// Current balance: filled by [fetchBalance] and kept up to date by the
  /// WebSocket `account` channel.
  @override
  ValueListenable<BalanceModel?> get balance => _balance;

  /// Open positions: seeded by [fetchPositions], updated by the private
  /// `positions` channel and re-priced on every public mark-price tick.
  @override
  ValueListenable<List<PositionModel>?> get positions => _positions;

  /// Aligns the signing clock with OKX server time so signed requests stay
  /// inside OKX's ~30s window. Best-effort: on failure the previous offset
  /// (or local time) is kept. Call before the first signed request.
  Future<void> syncServerTime() async {
    final result = await _api.fetchServerTime();
    result.fold(
      (serverMs) =>
          _clock.offsetMs = serverMs - DateTime.now().millisecondsSinceEpoch,
      (_) {},
    );
  }

  @override
  Future<Result<BalanceModel, Object>> fetchBalance() async {
    final result = await _api.fetchBalance();

    return result.map((dto) {
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
  }

  @override
  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    final result = await _api.fetchPositions();

    return result.map((dtoList) {
      final models = dtoList.map((dto) => dto.toModel()).toList();
      _positionsByKey
        ..clear()
        ..addEntries(models.map((model) => MapEntry(_key(model), model)));
      _publishPositions();
      _syncMarkPriceSubscriptions();
      return models;
    });
  }

  void _onPositionEvent(PositionDto dto) {
    final model = dto.toModel();
    final key = _key(model);
    if (model.size == 0) {
      _positionsByKey.remove(key);
    } else {
      // Keep the locally tracked mark price: mark-price ticks are fresher
      // than the position event's snapshot.
      final current = _positionsByKey[key];
      final markPrice = current != null && current.markPrice > 0
          ? current.markPrice
          : model.markPrice;
      _positionsByKey[key] = model.copyWith(
        markPrice: markPrice,
        unrealisedPnl: markPrice > 0
            ? _pnl(model.side, model.size, model.avgPrice, markPrice)
            : model.unrealisedPnl,
      );
    }
    _publishPositions();
    _syncMarkPriceSubscriptions();
  }

  void _syncMarkPriceSubscriptions() {
    final markPriceSubscriptions = _markPriceSubscriptions;
    if (markPriceSubscriptions == null) return;

    final openSymbols =
        _positionsByKey.values.map((position) => position.symbol).toSet();

    for (final symbol in openSymbols) {
      if (_markPriceSubs.containsKey(symbol)) continue;
      _markPriceSubs[symbol] = markPriceSubscriptions.subscribe(symbol).listen(
        (dto) {
          final markPxRaw = dto.markPx;
          if (markPxRaw == null || markPxRaw.isEmpty) return;
          _applyMarkPrice(dto.instId, double.parse(markPxRaw));
        },
      );
    }

    for (final symbol in _markPriceSubs.keys.toList()) {
      if (openSymbols.contains(symbol)) continue;
      unawaited(_markPriceSubs.remove(symbol)?.cancel());
      markPriceSubscriptions.unsubscribe(symbol);
    }
  }

  void _applyMarkPrice(String symbol, double markPrice) {
    var changed = false;
    for (final entry in _positionsByKey.entries.toList()) {
      final position = entry.value;
      if (position.symbol != symbol) continue;
      _positionsByKey[entry.key] = position.copyWith(
        markPrice: markPrice,
        unrealisedPnl:
            _pnl(position.side, position.size, position.avgPrice, markPrice),
      );
      changed = true;
    }
    if (changed) _publishPositions();
  }

  void _publishPositions() {
    final list = _positionsByKey.values.toList()
      ..sort((a, b) => a.symbol.compareTo(b.symbol));
    _positions.value = list;
  }

  static double _pnl(String side, double size, double avgPrice, double mark) =>
      side == 'short' ? size * (avgPrice - mark) : size * (mark - avgPrice);

  static String _key(PositionModel position) =>
      '${position.symbol}#${position.side}';

  @override
  void dispose() {
    _accountSub?.cancel();
    _positionSub?.cancel();
    for (final sub in _markPriceSubs.values) {
      sub.cancel();
    }
    _markPriceSubs.clear();
    _balance.dispose();
    _positions.dispose();
  }
}
