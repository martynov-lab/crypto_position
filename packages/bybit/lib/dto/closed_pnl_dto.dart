class ClosedPnlDto {
  final String symbol;
  final String orderId;
  final String side;
  final String qty;
  final String orderPrice;
  final String orderType;
  final String execType;
  final String closedSize;
  final String cumEntryValue;
  final String avgEntryPrice;
  final String cumExitValue;
  final String avgExitPrice;
  final String closedPnl;
  final String fillCount;
  final String leverage;
  final String createdTime;
  final String updatedTime;

  ClosedPnlDto({
    required this.symbol,
    required this.orderId,
    required this.side,
    required this.qty,
    required this.orderPrice,
    required this.orderType,
    required this.execType,
    required this.closedSize,
    required this.cumEntryValue,
    required this.avgEntryPrice,
    required this.cumExitValue,
    required this.avgExitPrice,
    required this.closedPnl,
    required this.fillCount,
    required this.leverage,
    required this.createdTime,
    required this.updatedTime,
  });

  factory ClosedPnlDto.fromJson(Map<String, dynamic> json) {
    return ClosedPnlDto(
      symbol: json['symbol'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      side: json['side'] as String? ?? '',
      qty: '${json['qty'] ?? '0'}',
      orderPrice: '${json['orderPrice'] ?? '0'}',
      orderType: json['orderType'] as String? ?? '',
      execType: json['execType'] as String? ?? '',
      closedSize: '${json['closedSize'] ?? '0'}',
      cumEntryValue: '${json['cumEntryValue'] ?? '0'}',
      avgEntryPrice: '${json['avgEntryPrice'] ?? '0'}',
      cumExitValue: '${json['cumExitValue'] ?? '0'}',
      avgExitPrice: '${json['avgExitPrice'] ?? '0'}',
      closedPnl: '${json['closedPnl'] ?? '0'}',
      fillCount: '${json['fillCount'] ?? '0'}',
      leverage: '${json['leverage'] ?? '0'}',
      createdTime: '${json['createdTime'] ?? '0'}',
      updatedTime: '${json['updatedTime'] ?? '0'}',
    );
  }
}

class ClosedPnlPageDto {
  final List<ClosedPnlDto> list;
  final String? nextPageCursor;

  ClosedPnlPageDto({required this.list, this.nextPageCursor});
}

class ExecutionDto {
  final String symbol;
  final String orderId;
  final String execId;
  final String side;
  final String execPrice;
  final String execQty;
  final String execValue;
  final String execType;
  final String execFee;
  final String feeRate;
  final String closedSize;
  final String orderType;
  final String execTime;

  ExecutionDto({
    required this.symbol,
    required this.orderId,
    required this.execId,
    required this.side,
    required this.execPrice,
    required this.execQty,
    required this.execValue,
    required this.execType,
    required this.execFee,
    required this.feeRate,
    required this.closedSize,
    required this.orderType,
    required this.execTime,
  });

  factory ExecutionDto.fromJson(Map<String, dynamic> json) {
    return ExecutionDto(
      symbol: json['symbol'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      execId: json['execId'] as String? ?? '',
      side: json['side'] as String? ?? '',
      execPrice: '${json['execPrice'] ?? '0'}',
      execQty: '${json['execQty'] ?? '0'}',
      execValue: '${json['execValue'] ?? '0'}',
      execType: json['execType'] as String? ?? '',
      execFee: '${json['execFee'] ?? '0'}',
      feeRate: '${json['feeRate'] ?? '0'}',
      closedSize: '${json['closedSize'] ?? '0'}',
      orderType: json['orderType'] as String? ?? '',
      execTime: '${json['execTime'] ?? '0'}',
    );
  }
}
