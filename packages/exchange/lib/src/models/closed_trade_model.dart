import 'package:freezed_annotation/freezed_annotation.dart';

part 'closed_trade_model.freezed.dart';

/// One closed (realized-PnL) trade, shared across every exchange so the trade
/// journal renders Bybit and OKX through the same widgets.
@freezed
abstract class ClosedTradeModel with _$ClosedTradeModel {
  const ClosedTradeModel._();

  const factory ClosedTradeModel({
    required String symbol,
    required String orderId,
    required String side,
    required double qty,
    required double orderPrice,
    required String orderType,
    required double avgEntryPrice,
    required double avgExitPrice,
    required double closedPnl,
    required double leverage,
    required double cumEntryValue,
    required double cumExitValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ClosedTradeModel;

  bool get isProfitable => closedPnl >= 0;

  String get tradeType {
    if (side == 'Buy') return 'Шорт';
    return 'Лонг';
  }

  String get resultLabel => isProfitable ? 'Прибыль' : 'Убыток';
}
