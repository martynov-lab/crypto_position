import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() => PositionModel(
        symbol: instrument,
        // `holdSide` (long/short) is Bitget's native wording; PnL sign is
        // resolved from it inside the repository.
        side: holdSide,
        size: _parseAmount(total).abs(),
        avgPrice: _parseAmount(openPriceAvg),
        markPrice: _parseAmount(markPrice),
        unrealisedPnl: _parseAmount(unrealizedPL),
        leverage: _parseAmount(leverage),
      );
}

/// Bitget returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
