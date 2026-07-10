import 'package:json_annotation/json_annotation.dart';

part 'history_position_dto.g.dart';

/// One closed position from REST `/private/position/list/history_positions`.
///
/// [positionType] is 1=long, 2=short; [realised] is the realized PnL;
/// [closeVol] is the closed size in contracts; [updateTime] is the close time
/// in milliseconds since epoch.
@JsonSerializable(checked: true, createToJson: false)
class HistoryPositionDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: 0)
  final int positionType;
  @JsonKey(defaultValue: 0)
  final num openAvgPrice;
  @JsonKey(defaultValue: 0)
  final num closeAvgPrice;
  @JsonKey(defaultValue: 0)
  final num closeVol;
  @JsonKey(defaultValue: 0)
  final num realised;
  @JsonKey(defaultValue: 0)
  final num leverage;
  @JsonKey(defaultValue: 0)
  final num updateTime;

  const HistoryPositionDto({
    required this.symbol,
    required this.positionType,
    required this.openAvgPrice,
    required this.closeAvgPrice,
    required this.closeVol,
    required this.realised,
    required this.leverage,
    required this.updateTime,
  });

  factory HistoryPositionDto.fromJson(Map<String, Object?> json) =>
      _$HistoryPositionDtoFromJson(json);
}
