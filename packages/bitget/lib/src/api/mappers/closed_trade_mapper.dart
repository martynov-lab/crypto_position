import 'package:exchange/exchange.dart';

import '../dto/position_history_dto.dart';

extension ClosedTradeMapper on PositionHistoryDto {
  ClosedTradeModel toModel() {
    final qty = _parseAmount(closeTotalPos).abs();
    final entry = _parseAmount(openAvgPrice);
    final exit = _parseAmount(closeAvgPrice);
    // Close time drives the journal calendar, matching Bybit/OKX.
    final closedAt = _parseTime(utime);
    return ClosedTradeModel(
      symbol: symbol,
      orderId: '',
      // ClosedTradeModel.tradeType keys off the closing order side: closing a
      // short is a 'Buy', closing a long is a 'Sell'.
      side: holdSide == 'short' ? 'Buy' : 'Sell',
      qty: qty,
      orderPrice: exit,
      orderType: '',
      avgEntryPrice: entry,
      avgExitPrice: exit,
      closedPnl: _parseAmount(netProfit),
      leverage: _parseAmount(leverage),
      cumEntryValue: entry * qty,
      cumExitValue: exit * qty,
      createdAt: closedAt,
      updatedAt: closedAt,
    );
  }
}

/// Bitget returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);

DateTime _parseTime(String value) =>
    DateTime.fromMillisecondsSinceEpoch(int.tryParse(value) ?? 0);
