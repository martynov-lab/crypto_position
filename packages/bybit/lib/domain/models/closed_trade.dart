class ClosedTrade {
  final String symbol;
  final String orderId;
  final String side;
  final double qty;
  final double orderPrice;
  final String orderType;
  final double avgEntryPrice;
  final double avgExitPrice;
  final double closedPnl;
  final double leverage;
  final double cumEntryValue;
  final double cumExitValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClosedTrade({
    required this.symbol,
    required this.orderId,
    required this.side,
    required this.qty,
    required this.orderPrice,
    required this.orderType,
    required this.avgEntryPrice,
    required this.avgExitPrice,
    required this.closedPnl,
    required this.leverage,
    required this.cumEntryValue,
    required this.cumExitValue,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProfitable => closedPnl >= 0;

  String get tradeType {
    if (side == 'Buy') return 'Закрыть шорт';
    return 'Закрыть лонг';
  }

  String get resultLabel => isProfitable ? 'Успешная сделка' : 'Убыток';
}
