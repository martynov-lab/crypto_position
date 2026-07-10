import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() {
    final mark = _parseAmount(markPrice);
    // Gate reports size in contracts; the base quantity is |value|/mark, which
    // is constant in the mark. Fall back to the raw contract count if the mark
    // is missing (live PnL then only refreshes once the mark arrives).
    final quantity = mark > 0 ? _parseAmount(value).abs() / mark : size.abs().toDouble();
    return PositionModel(
      symbol: contract,
      // Sign of `size` is Gate's native direction wording.
      side: size < 0 ? 'short' : 'long',
      size: quantity,
      avgPrice: _parseAmount(entryPrice),
      markPrice: mark,
      unrealisedPnl: _parseAmount(unrealisedPnl),
      leverage: _parseAmount(leverage),
    );
  }
}

/// Gate returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
