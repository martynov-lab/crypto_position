import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  /// [contractSize] converts [holdVol] (in contracts) to the base quantity.
  /// Mark price and unrealised PnL are seeded to 0 here — MEXC's position
  /// endpoint carries neither; the repository fills them from the ticker.
  PositionModel toModel(double contractSize) {
    final ms = createTime?.toInt();
    final createdAt = (ms == null || ms <= 0)
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms);

    return PositionModel(
      symbol: symbol,
      // positionType 1=long, 2=short — mapped to the native words used by the
      // repository's PnL formula.
      side: positionType == 2 ? 'short' : 'long',
      size: holdVol.toDouble() * contractSize,
      avgPrice: holdAvgPrice.toDouble(),
      markPrice: 0,
      unrealisedPnl: 0,
      leverage: leverage.toDouble(),
      createdAt: createdAt,
      // MEXC totals funding on the position but nothing equivalent for trading
      // fees, so paidCommission stays null and the card shows a dash.
      paidFunding: holdFee?.toDouble(),
      feesSince: holdFee == null ? null : createdAt,
    );
  }
}
