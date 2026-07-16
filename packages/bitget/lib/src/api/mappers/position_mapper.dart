import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() {
    final createdAt = _parseTimestamp(cTime);
    // Bitget signs a charge negative; paidCommission counts a charge positive.
    final deducted = _parseOptionalAmount(deductedFee);

    return PositionModel(
      symbol: instrument,
      // `holdSide` (long/short) is Bitget's native wording; PnL sign is
      // resolved from it inside the repository.
      side: holdSide,
      size: _parseAmount(total).abs(),
      avgPrice: _parseAmount(openPriceAvg),
      markPrice: _parseAmount(markPrice),
      unrealisedPnl: _parseAmount(unrealizedPL),
      leverage: _parseAmount(leverage),
      createdAt: createdAt,
      paidCommission: deducted == null ? null : -deducted,
      paidFunding: _parseOptionalAmount(totalFee),
      // Both totals accumulate over the whole position, so the window is never
      // truncated the way a transaction-log walk would be.
      feesSince: createdAt,
    );
  }
}

/// Bitget returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);

/// Null when the field is absent, keeping "not reported" distinct from a
/// genuine zero. The WS `positions` channel omits fees on some frames.
double? _parseOptionalAmount(String value) =>
    value.isEmpty ? null : double.tryParse(value);

DateTime? _parseTimestamp(String value) {
  final ms = int.tryParse(value);
  if (ms == null || ms <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}
