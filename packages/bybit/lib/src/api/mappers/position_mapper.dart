import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() => PositionModel(
        symbol: symbol,
        side: side,
        size: _parseAmount(size),
        // REST fills avgPrice, the WS position topic fills entryPrice.
        avgPrice: avgPrice.isNotEmpty && avgPrice != '0'
            ? _parseAmount(avgPrice)
            : _parseAmount(entryPrice),
        markPrice: _parseAmount(markPrice),
        unrealisedPnl: _parseAmount(unrealisedPnl),
        leverage: _parseAmount(leverage),
        createdAt: _parseTimestamp(createdTime),
      );
}

/// Bybit returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);

/// Epoch-ms string, or null when the field is absent (the WS position topic
/// omits it on some frames).
DateTime? _parseTimestamp(String value) {
  final ms = int.tryParse(value);
  if (ms == null || ms <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}
