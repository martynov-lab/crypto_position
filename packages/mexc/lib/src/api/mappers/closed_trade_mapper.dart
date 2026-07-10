import 'package:exchange/exchange.dart';

import '../dto/history_position_dto.dart';

extension ClosedTradeMapper on HistoryPositionDto {
  /// [contractSize] converts [closeVol] (in contracts) to the base quantity.
  ClosedTradeModel toModel(double contractSize) {
    final qty = closeVol.toDouble().abs() * contractSize;
    final entry = openAvgPrice.toDouble();
    final exit = closeAvgPrice.toDouble();
    // Close time drives the journal calendar, matching the other exchanges.
    final closedAt = DateTime.fromMillisecondsSinceEpoch(updateTime.toInt());
    return ClosedTradeModel(
      symbol: symbol,
      orderId: '',
      // ClosedTradeModel.tradeType keys off the closing order side: closing a
      // short (positionType 2) is a 'Buy', closing a long is a 'Sell'.
      side: positionType == 2 ? 'Buy' : 'Sell',
      qty: qty,
      orderPrice: exit,
      orderType: '',
      avgEntryPrice: entry,
      avgExitPrice: exit,
      closedPnl: realised.toDouble(),
      leverage: leverage.toDouble(),
      cumEntryValue: entry * qty,
      cumExitValue: exit * qty,
      createdAt: closedAt,
      updatedAt: closedAt,
    );
  }
}
