import 'package:json_annotation/json_annotation.dart';

part 'position_dto.g.dart';

/// Open position from REST `/v5/position/list` or the WS `position` topic.
///
/// REST reports the entry price as `avgPrice`, the WS topic as `entryPrice`;
/// both are kept and the mapper picks the populated one.
@JsonSerializable(checked: true, createToJson: false)
class PositionDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: '')
  final String side;
  @JsonKey(defaultValue: '0')
  final String size;
  @JsonKey(defaultValue: '0')
  final String avgPrice;
  @JsonKey(defaultValue: '0')
  final String entryPrice;
  @JsonKey(defaultValue: '0')
  final String markPrice;
  @JsonKey(defaultValue: '0')
  final String unrealisedPnl;
  @JsonKey(defaultValue: '0')
  final String leverage;
  @JsonKey(defaultValue: 0)
  final int positionIdx;

  /// Epoch milliseconds the position was opened, as a string. Anchors the
  /// fee/funding window.
  @JsonKey(defaultValue: '')
  final String createdTime;

  const PositionDto({
    required this.symbol,
    required this.side,
    required this.size,
    required this.avgPrice,
    required this.entryPrice,
    required this.markPrice,
    required this.unrealisedPnl,
    required this.leverage,
    required this.positionIdx,
    required this.createdTime,
  });

  factory PositionDto.fromJson(Map<String, Object?> json) =>
      _$PositionDtoFromJson(json);
}
