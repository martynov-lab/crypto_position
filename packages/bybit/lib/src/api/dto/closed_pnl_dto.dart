import 'package:json_annotation/json_annotation.dart';

part 'closed_pnl_dto.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class ClosedPnlDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: '')
  final String orderId;
  @JsonKey(defaultValue: '')
  final String side;
  @JsonKey(defaultValue: '0')
  final String qty;
  @JsonKey(defaultValue: '0')
  final String orderPrice;
  @JsonKey(defaultValue: '')
  final String orderType;
  @JsonKey(defaultValue: '0')
  final String avgEntryPrice;
  @JsonKey(defaultValue: '0')
  final String avgExitPrice;
  @JsonKey(defaultValue: '0')
  final String closedPnl;
  @JsonKey(defaultValue: '0')
  final String leverage;
  @JsonKey(defaultValue: '0')
  final String cumEntryValue;
  @JsonKey(defaultValue: '0')
  final String cumExitValue;
  @JsonKey(defaultValue: '0')
  final String createdTime;
  @JsonKey(defaultValue: '0')
  final String updatedTime;

  const ClosedPnlDto({
    required this.symbol,
    required this.orderId,
    required this.side,
    required this.qty,
    required this.orderPrice,
    required this.orderType,
    required this.avgEntryPrice,
    required this.avgExitPrice,
    required this.closedPnl,
    required this.leverage,
    required this.cumEntryValue,
    required this.cumExitValue,
    required this.createdTime,
    required this.updatedTime,
  });

  factory ClosedPnlDto.fromJson(Map<String, Object?> json) =>
      _$ClosedPnlDtoFromJson(json);
}
