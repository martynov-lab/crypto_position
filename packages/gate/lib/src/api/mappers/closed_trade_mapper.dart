import 'package:exchange/exchange.dart';

import '../dto/position_close_dto.dart';

extension ClosedTradeMapper on PositionCloseDto {
  ClosedTradeModel toModel() {
    final qty = _parseAmount(accumSize).abs();
    // long_price is the long-open / short-close price; short_price the inverse.
    final isLong = side == 'long';
    final entry = _parseAmount(isLong ? longPrice : shortPrice);
    final exit = _parseAmount(isLong ? shortPrice : longPrice);
    // Close time drives the journal calendar, matching the other exchanges.
    final closedAt = DateTime.fromMillisecondsSinceEpoch((time * 1000).round());
    return ClosedTradeModel(
      symbol: contract,
      orderId: '',
      // ClosedTradeModel.tradeType keys off the closing order side: closing a
      // short is a 'Buy', closing a long is a 'Sell'.
      side: side == 'short' ? 'Buy' : 'Sell',
      qty: qty,
      orderPrice: exit,
      orderType: '',
      avgEntryPrice: entry,
      avgExitPrice: exit,
      closedPnl: _parseAmount(pnl),
      leverage: 0,
      cumEntryValue: entry * qty,
      cumExitValue: exit * qty,
      createdAt: closedAt,
      updatedAt: closedAt,
    );
  }
}

/// Gate returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
