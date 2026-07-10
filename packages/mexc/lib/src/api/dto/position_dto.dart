import 'package:json_annotation/json_annotation.dart';

part 'position_dto.g.dart';

/// Open position from REST `/private/position/open_positions` or the private
/// `push.personal.position` channel.
///
/// [holdVol] is the size in **contracts**; the base quantity is
/// `holdVol * contractSize` (from the contract detail). [positionType] is
/// 1=long, 2=short. [state] is 1=holding, 3=closed. MEXC sends numbers as JSON
/// numbers and does not include an unrealized-PnL field here (it is derived
/// from the mark price).
@JsonSerializable(checked: true, createToJson: false)
class PositionDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: 0)
  final num holdVol;
  @JsonKey(defaultValue: 0)
  final num holdAvgPrice;
  @JsonKey(defaultValue: 0)
  final int positionType;
  @JsonKey(defaultValue: 0)
  final num leverage;
  @JsonKey(defaultValue: 1)
  final int state;

  const PositionDto({
    required this.symbol,
    required this.holdVol,
    required this.holdAvgPrice,
    required this.positionType,
    required this.leverage,
    required this.state,
  });

  factory PositionDto.fromJson(Map<String, Object?> json) =>
      _$PositionDtoFromJson(json);
}
