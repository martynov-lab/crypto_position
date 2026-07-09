import 'package:json_annotation/json_annotation.dart';

part 'positions_history_dto.g.dart';

/// One closed position from REST `/api/v5/account/positions-history`.
///
/// [direction] is `long` or `short`; [realizedPnl] is the net realized PnL
/// (price PnL + fees + funding). [cTime]/[uTime] are the open/close times in
/// milliseconds since epoch.
@JsonSerializable(checked: true, createToJson: false)
class PositionsHistoryDto {
  @JsonKey(defaultValue: '')
  final String instId;
  @JsonKey(defaultValue: '')
  final String posId;
  @JsonKey(defaultValue: '')
  final String direction;
  @JsonKey(defaultValue: '0')
  final String lever;
  @JsonKey(defaultValue: '0')
  final String openAvgPx;
  @JsonKey(defaultValue: '0')
  final String closeAvgPx;
  @JsonKey(defaultValue: '0')
  final String closeTotalPos;
  @JsonKey(defaultValue: '0')
  final String realizedPnl;
  @JsonKey(defaultValue: '0')
  final String cTime;
  @JsonKey(defaultValue: '0')
  final String uTime;

  const PositionsHistoryDto({
    required this.instId,
    required this.posId,
    required this.direction,
    required this.lever,
    required this.openAvgPx,
    required this.closeAvgPx,
    required this.closeTotalPos,
    required this.realizedPnl,
    required this.cTime,
    required this.uTime,
  });

  factory PositionsHistoryDto.fromJson(Map<String, Object?> json) =>
      _$PositionsHistoryDtoFromJson(json);
}
