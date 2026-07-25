import 'package:exchange/exchange.dart';

import '../dto/position_dto.dart';

extension PositionMapper on PositionDto {
  PositionModel toModel() {
    final createdAt = _parseTimestamp(cTime);
    // OKX signs a charge negative; paidCommission counts a charge as positive.
    final paidCommission = _parseOptionalAmount(fee);

    return PositionModel(
      symbol: instId,
      side: _side(posSide, pos),
      // `pos` is signed (negative for a net short); size is its magnitude.
      size: _parseAmount(pos).abs(),
      avgPrice: _parseAmount(avgPx),
      markPrice: _parseAmount(markPx),
      unrealisedPnl: _parseAmount(upl),
      leverage: _parseAmount(lever),
      createdAt: createdAt,
      paidCommission: paidCommission == null ? null : -paidCommission,
      paidFunding: _parseOptionalAmount(fundingFee),
      // Both totals accumulate over the whole position, so the window is never
      // truncated the way a transaction-log walk would be.
      feesSince: createdAt,
    );
  }
}

/// The position's direction in OKX's own wording.
///
/// A hedge-mode account reports it directly in `posSide` (`long`/`short`). A
/// net-mode account reports `net` and puts the direction in the sign of [pos] —
/// without unpacking it every net position would look like a long, which flips
/// the PnL and funding signs and makes it impossible to tell which side an
/// order must take to close the position. `pos: 0` carries no direction; it
/// only ever arrives on the frame that closes a position, which the repository
/// handles by instrument rather than by side.
String _side(String posSide, String pos) {
  if (posSide == 'long' || posSide == 'short') return posSide;
  return _parseAmount(pos) < 0 ? 'short' : 'long';
}

/// OKX returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);

/// Null when the field is absent, which keeps "not reported" distinct from a
/// genuine zero. The WS `positions` channel omits fees on some frames.
double? _parseOptionalAmount(String value) =>
    value.isEmpty ? null : double.tryParse(value);

DateTime? _parseTimestamp(String value) {
  final ms = int.tryParse(value);
  if (ms == null || ms <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}
