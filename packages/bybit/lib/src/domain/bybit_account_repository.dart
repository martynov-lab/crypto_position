import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../api/bybit_account_api.dart';
import '../api/dto/position_dto.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import '../api/position_subscriber.dart';
import '../api/ticker_subscriptions.dart';
import '../api/wallet_subscriber.dart';
import 'models/closed_trade_model.dart';
import 'models/position_model.dart';
import 'models/wallet_balance_model.dart';

class BybitAccountRepository {
  final BybitAccountApi _api;
  final TickerSubscriptions? _tickerSubscriptions;
  final ValueNotifier<WalletBalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<List<PositionModel>?> _positions = ValueNotifier(null);

  /// Open positions keyed by '$symbol#$positionIdx'.
  final _positionsByKey = <String, PositionModel>{};
  final _tickerSubs = <String, StreamSubscription<void>>{};

  StreamSubscription<void>? _walletSub;
  StreamSubscription<void>? _positionSub;

  BybitAccountRepository({
    required BybitAccountApi bybitAccountApi,
    WalletSubscriber? walletSubscriber,
    PositionSubscriber? positionSubscriber,
    TickerSubscriptions? tickerSubscriptions,
  })  : _api = bybitAccountApi,
        _tickerSubscriptions = tickerSubscriptions {
    _walletSub = walletSubscriber?.stream.listen(
      (dto) => _balance.value = dto.toModel(),
    );
    _positionSub = positionSubscriber?.stream.listen(_onPositionEvent);
  }

  /// Current wallet balance: filled by [fetchWalletBalance] and kept
  /// up to date by the WebSocket wallet stream.
  ValueListenable<WalletBalanceModel?> get balance => _balance;

  /// Open positions: seeded by [fetchPositions], updated by the private
  /// `position` topic and re-priced on every public ticker tick.
  ValueListenable<List<PositionModel>?> get positions => _positions;

  Future<Result<WalletBalanceModel, Object>> fetchWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final result = await _api.fetchWalletBalance(accountType: accountType);

    return result.map((dto) {
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
  }

  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    final result = await _api.fetchPositions();

    return result.map((dtoList) {
      final models = dtoList.map((dto) => dto.toModel()).toList();
      _positionsByKey
        ..clear()
        ..addEntries(models.map((model) => MapEntry(_key(model), model)));
      _publishPositions();
      _syncTickerSubscriptions();
      return models;
    });
  }

  Future<Result<List<ClosedTradeModel>, Object>> fetchClosedTrades({
    required String category,
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _api.fetchClosedPnl(
      category: category,
      symbol: symbol,
      startTime: startDate?.millisecondsSinceEpoch,
      endTime: endDate?.millisecondsSinceEpoch,
    );

    return result.map(
      (dtoList) => dtoList.map((dto) => dto.toModel()).toList(),
    );
  }

  void _onPositionEvent(PositionDto dto) {
    final model = dto.toModel();
    final key = _key(model);
    if (model.size == 0) {
      _positionsByKey.remove(key);
    } else {
      // Keep the locally tracked mark price: ticker ticks are fresher
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
          _applyMarkPrice(dto.symbol, double.parse(markPriceRaw));
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
      side == 'Buy' ? size * (mark - avgPrice) : size * (avgPrice - mark);

  static String _key(PositionModel position) =>
      '${position.symbol}#${position.positionIdx}';

  void dispose() {
    _walletSub?.cancel();
    _positionSub?.cancel();
    for (final sub in _tickerSubs.values) {
      sub.cancel();
    }
    _tickerSubs.clear();
    _balance.dispose();
    _positions.dispose();
  }
}
