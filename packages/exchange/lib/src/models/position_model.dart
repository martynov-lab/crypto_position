import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_model.freezed.dart';

/// Exchange-agnostic open position.
///
/// [side] keeps each exchange's own wording (e.g. Bybit `Buy`/`Sell`, OKX
/// `long`/`short`); PnL is computed inside each exchange's repository.
@freezed
abstract class PositionModel with _$PositionModel {
  const factory PositionModel({
    required String symbol,
    required String side,
    required double size,
    required double avgPrice,
    required double markPrice,
    required double unrealisedPnl,
    required double leverage,
  }) = _PositionModel;
}
