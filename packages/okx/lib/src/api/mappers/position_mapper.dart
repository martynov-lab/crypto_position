import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() => PositionModel(
        symbol: instId,
        side: posSide,
        // `pos` is signed (negative for a net short); size is its magnitude.
        size: _parseAmount(pos).abs(),
        avgPrice: _parseAmount(avgPx),
        markPrice: _parseAmount(markPx),
        unrealisedPnl: _parseAmount(upl),
        leverage: _parseAmount(lever),
      );
}

/// OKX returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
