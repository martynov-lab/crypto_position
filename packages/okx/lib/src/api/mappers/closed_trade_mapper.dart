import 'package:exchange/exchange.dart';

import '../dto/positions_history_dto.dart';

extension ClosedTradeMapper on PositionsHistoryDto {
  ClosedTradeModel toModel() {
    final qty = _parseAmount(closeTotalPos).abs();
    final entry = _parseAmount(openAvgPx);
    final exit = _parseAmount(closeAvgPx);
    // Close time drives the journal calendar, matching Bybit's closed-PnL date.
    final closedAt = _parseTime(uTime);
    return ClosedTradeModel(
      symbol: instId,
      orderId: posId,
      // ClosedTradeModel.tradeType keys off the closing order side: closing a
      // short is a 'Buy', closing a long is a 'Sell'.
      side: direction == 'short' ? 'Buy' : 'Sell',
      qty: qty,
      orderPrice: exit,
      orderType: '',
      avgEntryPrice: entry,
      avgExitPrice: exit,
      closedPnl: _parseAmount(realizedPnl),
      leverage: _parseAmount(lever),
      cumEntryValue: entry * qty,
      cumExitValue: exit * qty,
      createdAt: closedAt,
      updatedAt: closedAt,
    );
  }
}

/// OKX returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);

DateTime _parseTime(String value) =>
    DateTime.fromMillisecondsSinceEpoch(int.tryParse(value) ?? 0);
