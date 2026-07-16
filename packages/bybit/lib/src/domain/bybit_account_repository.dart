import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/bybit_account_api.dart';
import '../api/dto/position_dto.dart';
import '../api/dto/ticker_dto.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/mappers/transaction_log_mapper.dart';
import '../api/mappers/wallet_balance_mapper.dart';
import '../api/position_subscriber.dart';
import '../api/ticker_subscriptions.dart';
import '../api/wallet_subscriber.dart';

class BybitAccountRepository implements ExchangeAccountRepository {
  final BybitAccountApi _api;
  final TickerSubscriptions? _tickerSubscriptions;
  final ValueNotifier<BalanceModel?> _balance = ValueNotifier(null);
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

  /// Current wallet balance: filled by [fetchBalance] and kept
  /// up to date by the WebSocket wallet stream.
  @override
  ValueListenable<BalanceModel?> get balance => _balance;

  /// Open positions: seeded by [fetchPositions], updated by the private
  /// `position` topic and re-priced on every public ticker tick.
  @override
  ValueListenable<List<PositionModel>?> get positions => _positions;

  @override
  Future<Result<BalanceModel, Object>> fetchBalance() async {
    final result = await _api.fetchWalletBalance();

    return result.map((dto) {
      final model = dto.toModel();
      _balance.value = model;
      return model;
    });
  }

  @override
  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    final result = await _api.fetchPositions();

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        _positionsByKey.clear();
        for (final dto in value) {
          _positionsByKey[_key(dto)] = dto.toModel();
        }
        _publishPositions();
        _syncTickerSubscriptions();
        await _applyFees();
        return Ok(_positionsByKey.values.toList());
    }
  }

  /// Folds trading fees and funding from the account-wide transaction log into
  /// the open positions, each summed over its own life but no further back
  /// than [feesLookbackWindow].
  ///
  /// Best-effort: on failure the fee fields stay null and render as unknown,
  /// rather than failing the whole position fetch over a secondary detail.
  Future<void> _applyFees() async {
    final now = DateTime.now();
    final windowStart = now.subtract(feesLookbackWindow);

    final openedAt = _positionsByKey.values
        .map((position) => position.createdAt)
        .nonNulls;
    if (openedAt.isEmpty) return;

    // One request window covering the oldest position; the log is account-wide,
    // so each position is then summed from its own start below.
    final oldest = openedAt.reduce((a, b) => a.isBefore(b) ? a : b);

    final result = await _api.fetchTransactionLog(
      startTime: _feesSince(oldest, windowStart).millisecondsSinceEpoch,
      endTime: now.millisecondsSinceEpoch,
    );
    if (result case Ok(:final value)) {
      for (final entry in _positionsByKey.entries.toList()) {
        final position = entry.value;
        final createdAt = position.createdAt;
        if (createdAt == null) continue;

        final since = _feesSince(createdAt, windowStart);
        final fees = value.feesFor(position.symbol, since);
        _positionsByKey[entry.key] = position.copyWith(
          paidCommission: fees.commission,
          paidFunding: fees.funding,
          feesSince: since,
        );
      }
      _publishPositions();
    }
  }

  static DateTime _feesSince(DateTime createdAt, DateTime windowStart) =>
      createdAt.isBefore(windowStart) ? windowStart : createdAt;

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
    final key = _key(dto);
    if (model.size == 0) {
      _positionsByKey.remove(key);
    } else {
      // Keep the locally tracked mark price: ticker ticks are fresher
      // than the position event's snapshot.
      final current = _positionsByKey[key];
      final markPrice = current != null && current.markPrice > 0
          ? current.markPrice
          : model.markPrice;
      // The position topic reports neither funding (that rides the ticker) nor
      // fees (those come from the transaction log), so carry the known values
      // over instead of blanking those rows on every position event.
      final merged = model.copyWith(
        markPrice: markPrice,
        unrealisedPnl: markPrice > 0
            ? _pnl(model.side, model.size, model.avgPrice, markPrice)
            : model.unrealisedPnl,
        createdAt: model.createdAt ?? current?.createdAt,
        fundingRate: model.fundingRate ?? current?.fundingRate,
        nextFundingTime: model.nextFundingTime ?? current?.nextFundingTime,
        paidCommission: current?.paidCommission,
        paidFunding: current?.paidFunding,
        feesSince: current?.feesSince,
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
      _tickerSubs[symbol] = tickerSubscriptions.subscribe(symbol).listen(
        _applyTicker,
      );
    }

    for (final symbol in _tickerSubs.keys.toList()) {
      if (openSymbols.contains(symbol)) continue;
      unawaited(_tickerSubs.remove(symbol)?.cancel());
      tickerSubscriptions.unsubscribe(symbol);
    }
  }

  /// Re-prices open positions on the symbol and refreshes their funding.
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
      if (position.symbol != dto.symbol) continue;

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
    return position.side == 'Buy' ? -amount : amount;
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
      side == 'Buy' ? size * (mark - avgPrice) : size * (avgPrice - mark);

  static String _key(PositionDto dto) => '${dto.symbol}#${dto.positionIdx}';

  @override
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
