import 'package:freezed_annotation/freezed_annotation.dart';

part 'closed_trade_model.freezed.dart';

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
    if (side == 'Buy') return 'Закрыть шорт';
    return 'Закрыть лонг';
  }

  String get resultLabel => isProfitable ? 'Успешная сделка' : 'Убыток';
}
