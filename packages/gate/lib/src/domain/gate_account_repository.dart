import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/dto/position_dto.dart';
import '../api/dto/ticker_dto.dart';
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
    // The futures account is read only for the numeric user id, which Gate
    // requires in the private positions subscription. Its balance covers the
    // futures wallet alone and would miss funds held on spot, so the money
    // itself comes from the whole-account total below.
    if (await _api.fetchBalance() case Ok(:final value)) {
      userId = value.user;
    }

    final result = await _api.fetchTotalBalance();

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        final model = value.toModel();
        _balance.value = model;
        return Ok(model);
    }
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

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        // Gate lists every contract the user has touched, including flat ones.
        final models =
            value.map((dto) => dto.toModel()).where((m) => m.size > 0).toList();
        _positionsByKey
          ..clear()
          ..addEntries(models.map((model) => MapEntry(_key(model), model)));
        _publishPositions();
        _syncTickerSubscriptions();
        await _applyFundingSchedule();
        return Ok(_positionsByKey.values.toList());
    }
  }

  /// Fills in each position's next settlement time from the contracts endpoint,
  /// which is the only place Gate publishes it — the ticker carries the rate
  /// but not the schedule.
  ///
  /// Best-effort: on failure the time stays null and renders as unknown.
  Future<void> _applyFundingSchedule() async {
    if (_positionsByKey.isEmpty) return;

    final result = await _api.fetchContracts();
    if (result case Ok(:final value)) {
      final nextApplyByContract = {
        for (final contract in value) contract.name: contract.fundingNextApply,
      };

      var changed = false;
      for (final entry in _positionsByKey.entries.toList()) {
        final position = entry.value;
        final seconds = nextApplyByContract[position.symbol];
        if (seconds == null || seconds <= 0) continue;

        _positionsByKey[entry.key] = position.copyWith(
          // Gate times this in seconds, not milliseconds.
          nextFundingTime: DateTime.fromMillisecondsSinceEpoch(
            (seconds * 1000).toInt(),
          ),
        );
        changed = true;
      }
      if (changed) _publishPositions();
    }
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
      // The position channel carries no funding, so keep what the ticker and
      // the contracts endpoint already established.
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

  /// Re-prices open positions on the contract and refreshes their funding rate.
  /// A tick may carry either field alone, so each is applied independently.
  void _applyTicker(TickerDto dto) {
    final markPrice = _parseAmount(dto.markPrice);
    final fundingRate = _parseAmount(dto.fundingRate);
    if (markPrice == null && fundingRate == null) return;

    var changed = false;
    for (final entry in _positionsByKey.entries.toList()) {
      final position = entry.value;
      if (position.symbol != dto.contract) continue;

      final mark = markPrice ?? position.markPrice;
      final repriced = position.copyWith(
        markPrice: mark,
        unrealisedPnl: mark > 0
            ? _pnl(position.side, position.size, position.avgPrice, mark)
            : position.unrealisedPnl,
        fundingRate: fundingRate ?? position.fundingRate,
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

  /// Null when the tick omitted the field, so the caller keeps the old value.
  static double? _parseAmount(String? value) =>
      (value == null || value.isEmpty) ? null : double.tryParse(value);

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
