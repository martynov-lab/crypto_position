import 'dart:async';

import 'package:core/core.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';

import '../api/account_subscriber.dart';
import '../api/dto/balance_dto.dart';
import '../api/dto/position_dto.dart';
import '../api/mappers/balance_mapper.dart';
import '../api/mappers/closed_trade_mapper.dart';
import '../api/mappers/position_mapper.dart';
import '../api/mexc_account_api.dart';
import '../api/position_subscriber.dart';
import '../api/ticker_subscriptions.dart';

class MexcAccountRepository implements ExchangeAccountRepository {
  final MexcAccountApi _api;
  final TickerSubscriptions? _tickerSubscriptions;
  final ValueNotifier<BalanceModel?> _balance = ValueNotifier(null);
  final ValueNotifier<List<PositionModel>?> _positions = ValueNotifier(null);

  /// Open positions keyed by '$symbol#$side'.
  final _positionsByKey = <String, PositionModel>{};
  final _tickerSubs = <String, StreamSubscription<void>>{};

  /// symbol -> contractSize multiplier, fetched once from the public specs.
  final _contractSizes = <String, double>{};

  StreamSubscription<void>? _accountSub;
  StreamSubscription<void>? _positionSub;

  MexcAccountRepository({
    required MexcAccountApi mexcAccountApi,
    AccountSubscriber? accountSubscriber,
    PositionSubscriber? positionSubscriber,
    TickerSubscriptions? tickerSubscriptions,
  })  : _api = mexcAccountApi,
        _tickerSubscriptions = tickerSubscriptions {
    _accountSub = accountSubscriber?.stream.listen((dto) {
      // The USDT asset carries the account total; ignore other-currency pushes.
      if (dto.currency == 'USDT') {
        _balance.value = MexcBalanceDto([dto]).toModel();
      }
    });
    _positionSub = positionSubscriber?.stream.listen(_onPositionEvent);
  }

  @override
  ValueListenable<BalanceModel?> get balance => _balance;

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

  /// Closed positions whose close time falls in [[startDate], [endDate]). MEXC
  /// pages instead of filtering by time, so we fetch the most recent page and
  /// filter here (older trades beyond one page are not returned).
  Future<Result<List<ClosedTradeModel>, Object>> fetchClosedTrades({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _ensureContractSizes();
    final result = await _api.fetchHistoryPositions();
    return result.map(
      (dtoList) => dtoList
          .map((dto) => dto.toModel(_contractSize(dto.symbol)))
          .where((trade) => _inRange(trade.updatedAt, startDate, endDate))
          .toList(),
    );
  }

  @override
  Future<Result<List<PositionModel>, Object>> fetchPositions() async {
    await _ensureContractSizes();
    final result = await _api.fetchPositions();

    return result.map((dtoList) {
      final models = dtoList
          .where((dto) => dto.state != 3 && dto.holdVol != 0)
          .map((dto) => dto.toModel(_contractSize(dto.symbol)))
          .toList();
      _positionsByKey
        ..clear()
        ..addEntries(models.map((model) => MapEntry(_key(model), model)));
      _publishPositions();
      _syncTickerSubscriptions();
      // MEXC's position endpoint has no mark/PnL; seed both from the tickers.
      unawaited(_seedMarkPrices());
      return models;
    });
  }

  /// Seeds mark price and funding rate from the public tickers, then reads the
  /// settlement schedule the tickers do not carry.
  Future<void> _seedMarkPrices() async {
    final result = await _api.fetchTickers();
    result.fold(
      (tickers) {
        for (final ticker in tickers) {
          _applyTicker(ticker.symbol, ticker.fairPrice, ticker.fundingRate);
        }
      },
      (_) {},
    );
    await _applyFundingSchedule();
  }

  Future<void> _ensureContractSizes() async {
    if (_contractSizes.isNotEmpty) return;
    final result = await _api.fetchContractDetail();
    result.fold(
      (details) {
        for (final detail in details) {
          _contractSizes[detail.symbol] = detail.contractSize.toDouble();
        }
      },
      (_) {},
    );
  }

  double _contractSize(String symbol) => _contractSizes[symbol] ?? 1;

  void _onPositionEvent(PositionDto dto) {
    final model = dto.toModel(_contractSize(dto.symbol));
    final key = _key(model);
    if (dto.state == 3 || model.size == 0) {
      _positionsByKey.remove(key);
    } else {
      // Keep the locally tracked mark price: ticker ticks are fresher.
      final current = _positionsByKey[key];
      final markPrice = current != null && current.markPrice > 0
          ? current.markPrice
          : model.markPrice;
      // The position channel carries no funding rate or schedule, so keep what
      // the ticker and the funding-rate endpoint already established.
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
      _tickerSubs[symbol] = tickerSubscriptions.subscribe(symbol).listen(
        (dto) => _applyTicker(dto.symbol, dto.fairPrice, dto.fundingRate),
      );
    }

    for (final symbol in _tickerSubs.keys.toList()) {
      if (openSymbols.contains(symbol)) continue;
      unawaited(_tickerSubs.remove(symbol)?.cancel());
      tickerSubscriptions.unsubscribe(symbol);
    }
  }

  /// Re-prices open positions on the symbol and refreshes their funding rate.
  /// A tick may carry either field alone, so each is applied independently.
  void _applyTicker(String symbol, num? fairPrice, num? fundingRate) {
    if (fairPrice == null && fundingRate == null) return;

    var changed = false;
    for (final entry in _positionsByKey.entries.toList()) {
      final position = entry.value;
      if (position.symbol != symbol) continue;

      final mark = fairPrice?.toDouble() ?? position.markPrice;
      final repriced = position.copyWith(
        markPrice: mark,
        unrealisedPnl: mark > 0
            ? _pnl(position.side, position.size, position.avgPrice, mark)
            : position.unrealisedPnl,
        fundingRate: fundingRate?.toDouble() ?? position.fundingRate,
      );
      _positionsByKey[entry.key] = repriced.copyWith(
        upcomingFundingUsd: _upcomingFunding(repriced),
      );
      changed = true;
    }
    if (changed) _publishPositions();
  }

  /// Fills in each position's next settlement time, which MEXC publishes only
  /// on the per-symbol funding-rate endpoint. One request per open symbol.
  ///
  /// Best-effort: on failure the time stays null and renders as unknown.
  Future<void> _applyFundingSchedule() async {
    final openSymbols =
        _positionsByKey.values.map((position) => position.symbol).toSet();

    for (final symbol in openSymbols) {
      final result = await _api.fetchFundingRate(symbol);
      if (result case Ok(:final value)) {
        final ms = value.nextSettleTime?.toInt();
        if (ms == null || ms <= 0) continue;

        var changed = false;
        for (final entry in _positionsByKey.entries.toList()) {
          final position = entry.value;
          if (position.symbol != symbol) continue;
          _positionsByKey[entry.key] = position.copyWith(
            nextFundingTime: DateTime.fromMillisecondsSinceEpoch(ms),
          );
          changed = true;
        }
        if (changed) _publishPositions();
      }
    }
  }

  /// Funding due at the next settlement, signed from the account's point of
  /// view: on a positive rate a long pays and a short receives.
  static double? _upcomingFunding(PositionModel position) {
    final rate = position.fundingRate;
    if (rate == null || position.markPrice <= 0) return null;

    final amount = position.notional * rate;
    return position.side == 'short' ? amount : -amount;
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

  static bool _inRange(DateTime time, DateTime? start, DateTime? end) {
    if (start != null && time.isBefore(start)) return false;
    if (end != null && !time.isBefore(end)) return false;
    return true;
  }

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
