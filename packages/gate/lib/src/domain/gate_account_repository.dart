import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/dto/position_dto.dart';
import '../api/gate_account_api.dart';
import '../api/mappers/balance_mapper.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/position_subscriber.dart';
import '../api/ticker_subscriptions.dart';

class GateAccountRepository implements ExchangeAccountRepository {
  final GateAccountApi _api;
  final TickerSubscriptions? _tickerSubscriptions;
  final ValueNotifier<BalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<List<PositionModel>?> _positions = ValueNotifier(null);

  /// Open positions keyed by '$contract#$side'.
  final _positionsByKey = <String, PositionModel>{};
  final _tickerSubs = <String, StreamSubscription<void>>{};

  StreamSubscription<void>? _positionSub;

  /// Numeric account id, learned from [fetchBalance]; Gate needs it to
  /// subscribe to the private positions channel.
  int? userId;

  GateAccountRepository({
    required GateAccountApi gateAccountApi,
    PositionSubscriber? positionSubscriber,
    TickerSubscriptions? tickerSubscriptions,
  })  : _api = gateAccountApi,
        _tickerSubscriptions = tickerSubscriptions {
    _positionSub = positionSubscriber?.stream.listen(_onPositionEvent);
  }

  /// Current balance: filled by [fetchBalance] (REST). Gate's private balance
  /// channel is intentionally not wired; unrealised PnL still updates live via
  /// the per-position ticker stream.
  @override
  ValueListenable<BalanceModel?> get balance => _balance;

  /// Open positions: seeded by [fetchPositions], updated by the private
  /// `futures.positions` channel and re-priced on every public ticker tick.
  @override
  ValueListenable<List<PositionModel>?> get positions => _positions;

  @override
  Future<Result<BalanceModel, Object>> fetchBalance() async {
    final result = await _api.fetchBalance();

    return result.map((dto) {
      userId = dto.user;
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
  }

  /// Closed positions (realized-PnL history) whose close time falls in
  /// [[startDate], [endDate]). Mirrors the other exchanges' `fetchClosedTrades`
  /// so the trade journal renders every exchange the same way.
  Future<Result<List<ClosedTradeModel>, Object>> fetchClosedTrades({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _api.fetchPositionClose(
      from: startDate != null ? startDate.millisecondsSinceEpoch ~/ 1000 : null,
      to: endDate != null ? endDate.millisecondsSinceEpoch ~/ 1000 : null,
    );

    return result.map(
      (dtoList) => dtoList.map((dto) => dto.toModel()).toList(),
    );
  }

  @override
  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    final result = await _api.fetchPositions();

    return result.map((dtoList) {
      // Gate lists every contract the user has touched, including flat ones.
      final models =
          dtoList.map((dto) => dto.toModel()).where((m) => m.size > 0).toList();
      _positionsByKey
        ..clear()
        ..addEntries(models.map((model) => MapEntry(_key(model), model)));
      _publishPositions();
      _syncTickerSubscriptions();
      return models;
    });
  }

  void _onPositionEvent(PositionDto dto) {
    final model = dto.toModel();
    final key = _key(model);
    if (model.size == 0) {
      _positionsByKey.remove(key);
    } else {
      // Keep the locally tracked mark price: ticker ticks are fresher than the
      // position event's snapshot.
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
    _syncTickerSubscriptions();
  }

  void _syncTickerSubscriptions() {
    final tickerSubscriptions = _tickerSubscriptions;
    if (tickerSubscriptions == null) return;

    final openSymbols =
        _positionsByKey.values.map((position) => position.symbol).toSet();

    for (final symbol in openSymbols) {
      if (_tickerSubs.containsKey(symbol)) continue;
      _tickerSubs[symbol] = tickerSubscriptions.subscribe(symbol).listen(
        (dto) {
          final markPriceRaw = dto.markPrice;
          if (markPriceRaw == null || markPriceRaw.isEmpty) return;
          _applyMarkPrice(dto.contract, double.parse(markPriceRaw));
        },
      );
    }

    for (final symbol in _tickerSubs.keys.toList()) {
      if (openSymbols.contains(symbol)) continue;
      unawaited(_tickerSubs.remove(symbol)?.cancel());
      tickerSubscriptions.unsubscribe(symbol);
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
    _positionSub?.cancel();
    for (final sub in _tickerSubs.values) {
      sub.cancel();
    }
    _tickerSubs.clear();
    _balance.dispose();
    _positions.dispose();
  }
}
