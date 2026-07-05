import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_model.freezed.dart';

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
    required int positionIdx,
  }) = _PositionModel;
}
