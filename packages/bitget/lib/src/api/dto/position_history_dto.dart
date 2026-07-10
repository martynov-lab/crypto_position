import 'package:json_annotation/json_annotation.dart';

part 'position_history_dto.g.dart';

/// One closed position from REST `/api/v2/mix/position/history-position`.
///
/// [holdSide] is `long` or `short`; [netProfit] is the net realized PnL (price
/// PnL + fees + funding). [ctime]/[utime] are the open/close times in
/// milliseconds since epoch.
@JsonSerializable(checked: true, createToJson: false)
class PositionHistoryDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: '')
  final String holdSide;
  @JsonKey(defaultValue: '0')
  final String openAvgPrice;
  @JsonKey(defaultValue: '0')
  final String closeAvgPrice;
  @JsonKey(defaultValue: '0')
  final String closeTotalPos;
  @JsonKey(defaultValue: '0')
  final String netProfit;
  @JsonKey(defaultValue: '0')
  final String leverage;
  @JsonKey(defaultValue: '0')
  final String ctime;
  @JsonKey(defaultValue: '0')
  final String utime;

  const PositionHistoryDto({
    required this.symbol,
    required this.holdSide,
    required this.openAvgPrice,
    required this.closeAvgPrice,
    required this.closeTotalPos,
    required this.netProfit,
    required this.leverage,
    required this.ctime,
    required this.utime,
  });

  factory PositionHistoryDto.fromJson(Map<String, Object?> json) =>
      _$PositionHistoryDtoFromJson(json);
}
