import 'package:json_annotation/json_annotation.dart';

part 'position_dto.g.dart';

/// Open position from REST `/api/v5/account/positions` or the private
/// `positions` WebSocket channel. Both use identical field names.
///
/// [posSide] is `long`, `short`, or `net`; [pos] is the signed size (negative
/// for a net short).
///
/// [fee] and [fundingFee] accumulate over the position's life, so unlike Bybit
/// no transaction-log walk is needed to total them. Both are signed from the
/// account's point of view: negative is charged, positive is a rebate/income.
@JsonSerializable(checked: true, createToJson: false)
class PositionDto {
  @JsonKey(defaultValue: '')
  final String instId;
  @JsonKey(defaultValue: '')
  final String posSide;
  @JsonKey(defaultValue: '0')
  final String pos;
  @JsonKey(defaultValue: '0')
  final String avgPx;
  @JsonKey(defaultValue: '0')
  final String markPx;
  @JsonKey(defaultValue: '0')
  final String upl;
  @JsonKey(defaultValue: '0')
  final String lever;
  @JsonKey(defaultValue: '')
  final String fee;
  @JsonKey(defaultValue: '')
  final String fundingFee;

  /// Epoch milliseconds the position was opened, as a string.
  @JsonKey(defaultValue: '')
  final String cTime;

  const PositionDto({
    required this.instId,
    required this.posSide,
    required this.pos,
    required this.avgPx,
    required this.markPx,
    required this.upl,
    required this.lever,
    required this.fee,
    required this.fundingFee,
    required this.cTime,
  });

  factory PositionDto.fromJson(Map<String, Object?> json) =>
      _$PositionDtoFromJson(json);
}
