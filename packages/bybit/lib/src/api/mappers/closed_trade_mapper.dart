import '../../domain/models/closed_trade_model.dart';
import '../dto/closed_pnl_dto.dart';

extension ClosedTradeMapper on ClosedPnlDto {
  ClosedTradeModel toModel() => ClosedTradeModel(
        symbol: symbol,
        orderId: orderId,
        side: side,
        qty: _parseAmount(qty),
        orderPrice: _parseAmount(orderPrice),
        orderType: orderType,
        avgEntryPrice: _parseAmount(avgEntryPrice),
        avgExitPrice: _parseAmount(avgExitPrice),
        closedPnl: _parseAmount(closedPnl),
        leverage: _parseAmount(leverage),
        cumEntryValue: _parseAmount(cumEntryValue),
        cumExitValue: _parseAmount(cumExitValue),
        createdAt: _parseTime(createdTime),
        updatedAt: _parseTime(updatedTime),
      );
}

double _parseAmount(String value) => double.tryParse(value) ?? 0;

DateTime _parseTime(String value) =>
    DateTime.fromMillisecondsSinceEpoch(int.tryParse(value) ?? 0);
