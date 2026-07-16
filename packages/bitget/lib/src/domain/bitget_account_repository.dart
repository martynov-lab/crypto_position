import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/account_subscriber.dart';
import '../api/bitget_account_api.dart';
import '../api/dto/balance_dto.dart';
import '../api/dto/position_dto.dart';
import '../api/dto/ticker_dto.dart';
import '../api/mappers/balance_mapper.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/position_subscriber.dart';
import '../api/ticker_subscriptions.dart';

class BitgetAccountRepository implements ExchangeAccountRepository {
  final BitgetAccountApi _api;
  final TickerSubscriptions? _tickerSubscriptions;
  final ValueNotifier<BalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<List<PositionModel>?> _positions = ValueNotifier(null);

  /// Open positions keyed by '$symbol#$holdSide'.
  final _positionsByKey = <String, PositionModel>{};
  final _tickerSubs = <String, StreamSubscription<void>>{};

  StreamSubscription<void>? _accountSub;
  StreamSubscription<void>? _positionSub;

  BitgetAccountRepository({
    required BitgetAccountApi bitgetAccountApi,
    AccountSubscriber? accountSubscriber,
    PositionSubscriber? positionSubscriber,
    TickerSubscriptions? tickerSubscriptions,
  })  : _api = bitgetAccountApi,
        _tickerSubscriptions = tickerSubscriptions {
    // The USDT-FUTURES account channel streams the single USDT margin account.
    _accountSub = accountSubscriber?.stream.listen(
      (dto) => _balance.value = BitgetBalanceDto([dto]).toModel(),
    );
    _positionSub = positionSubscriber?.stream.listen(_onPositionEvent);
  }

  /// Current balance: filled by [fetchBalance] and kept up to date by the
  /// WebSocket `account` channel.
  @override
  ValueListenable<BalanceModel?> get balance => _balance;

  /// Open positions: seeded by [fetchPositions], updated by the private
  /// `positions` channel and re-priced on every public ticker tick.
  @override
  ValueListenable<List<PositionModel>?> get positions => _positions;

  @override
  Future<Result<BalanceModel, Object>> fetchBalance() async {
    final result = await _api.fetchBalance();

    return result.map((dto) {
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
  }

  /// Closed positions (realized-PnL history) whose close time falls in
  /// [[startDate], [endDate]). Mirrors Bybit/OKX's `fetchClosedTrades` so the
  /// trade journal renders every exchange the same way.
  Future<Result<List<ClosedTradeModel>, Object>> fetchClosedTrades({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _api.fetchPositionsHistory(
      startTime: startDate?.millisecondsSinceEpoch,
      endTime: endDate?.millisecondsSinceEpoch,
    );

    return result.map(
      (dtoList) => dtoList.map((dto) => dto.toModel()).toList(),
    );
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
      // The position channel carries no funding rate (that rides the ticker),
      // so keep the last known one instead of blanking the row.
      final merged = model.copyWith(
        markPrice: markPrice,
        unrealisedPnl: markPrice > 0
            ? _pnl(model.side, model.size, model.avgPrice, markPrice)
            : model.unrealisedPnl,
        fundingRate: model.fundingRate ?? current?.fundingRate,
        nextFundingTime: model.nextFundingTime ?? current?.nextFundingTime,
      );
      _positionsByKey[key] = merged.copyWith(
        upcomingFundingUsd: _upcomingFunding(merged),
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
      _tickerSubs[symbol] =
          tickerSubscriptions.subscribe(symbol).listen(_applyTicker);
    }

    for (final symbol in _tickerSubs.keys.toList()) {
      if (openSymbols.contains(symbol)) continue;
      unawaited(_tickerSubs.remove(symbol)?.cancel());
      tickerSubscriptions.unsubscribe(symbol);
    }
  }

  /// Re-prices open positions on the instrument and refreshes their funding.
  ///
  /// Delta frames carry only the changed fields, so each of the three is
  /// applied independently and a missing one keeps its current value.
  void _applyTicker(TickerDto dto) {
    final markPrice = _parseAmount(dto.markPrice);
    final fundingRate = _parseAmount(dto.fundingRate);
    final nextFundingTime = _parseTimestamp(dto.nextFundingTime);
    if (markPrice == null && fundingRate == null && nextFundingTime == null) {
      return;
    }

    var changed = false;
    for (final entry in _positionsByKey.entries.toList()) {
      final position = entry.value;
      if (position.symbol != dto.instId) continue;

      final mark = markPrice ?? position.markPrice;
      final repriced = position.copyWith(
        markPrice: mark,
        unrealisedPnl: mark > 0
            ? _pnl(position.side, position.size, position.avgPrice, mark)
            : position.unrealisedPnl,
        fundingRate: fundingRate ?? position.fundingRate,
        nextFundingTime: nextFundingTime ?? position.nextFundingTime,
      );
      _positionsByKey[entry.key] = repriced.copyWith(
        upcomingFundingUsd: _upcomingFunding(repriced),
      );
      changed = true;
    }
    if (changed) _publishPositions();
  }

  /// Funding due at the next settlement, signed from the account's point of
  /// view: on a positive rate a long pays and a short receives.
  static double? _upcomingFunding(PositionModel position) {
    final rate = position.fundingRate;
    if (rate == null || position.markPrice <= 0) return null;

    final amount = position.notional * rate;
    return position.side == 'short' ? amount : -amount;
  }

  /// Null when the frame omitted the field, so the caller keeps the old value.
  static double? _parseAmount(String? value) =>
      (value == null || value.isEmpty) ? null : double.tryParse(value);

  static DateTime? _parseTimestamp(String? value) {
    final ms = int.tryParse(value ?? '');
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
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
    for (final sub in _tickerSubs.values) {
      sub.cancel();
    }
    _tickerSubs.clear();
    _balance.dispose();
    _positions.dispose();
  }
}
