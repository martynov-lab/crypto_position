import '../domain/models/closed_trade.dart';
import '../dto/closed_pnl_dto.dart';

class ClosedTradeMapper {
  ClosedTrade fromDto(ClosedPnlDto dto) {
    return ClosedTrade(
      symbol: dto.symbol,
      orderId: dto.orderId,
      side: dto.side,
      qty: double.tryParse(dto.qty) ?? 0,
      orderPrice: double.tryParse(dto.orderPrice) ?? 0,
      orderType: dto.orderType,
      avgEntryPrice: double.tryParse(dto.avgEntryPrice) ?? 0,
      avgExitPrice: double.tryParse(dto.avgExitPrice) ?? 0,
      closedPnl: double.tryParse(dto.closedPnl) ?? 0,
      leverage: double.tryParse(dto.leverage) ?? 0,
      cumEntryValue: double.tryParse(dto.cumEntryValue) ?? 0,
      cumExitValue: double.tryParse(dto.cumExitValue) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(dto.createdTime) ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(dto.updatedTime) ?? 0,
      ),
    );
  }

  List<ClosedTrade> fromDtoList(List<ClosedPnlDto> dtoList) {
    return dtoList.map(fromDto).toList();
  }
}
