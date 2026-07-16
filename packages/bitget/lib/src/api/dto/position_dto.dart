import 'package:json_annotation/json_annotation.dart';

part 'position_dto.g.dart';

/// Open position from REST `/api/v2/mix/position/all-position` or the private
/// `positions` WebSocket channel.
///
/// REST reports the instrument in `symbol`; the WS channel uses `instId`, so
/// both are parsed and the mapper falls back to whichever is present.
/// [holdSide] is `long` or `short`; [total] is the (unsigned) position size.
@JsonSerializable(checked: true, createToJson: false)
class PositionDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: '')
  final String instId;
  @JsonKey(defaultValue: '')
  final String holdSide;
  @JsonKey(defaultValue: '0')
  final String total;
  @JsonKey(defaultValue: '0')
  final String openPriceAvg;
  @JsonKey(defaultValue: '0')
  final String markPrice;
  @JsonKey(defaultValue: '0')
  final String unrealizedPL;
  @JsonKey(defaultValue: '0')
  final String leverage;

  /// Epoch milliseconds the position was opened, as a string.
  @JsonKey(defaultValue: '')
  final String cTime;

  /// Funding accumulated over the position's life, signed from the account's
  /// point of view (negative is paid out).
  @JsonKey(defaultValue: '')
  final String totalFee;

  /// Trading fees accumulated over the position's life, signed the same way.
  @JsonKey(defaultValue: '')
  final String deductedFee;

  const PositionDto({
    required this.symbol,
    required this.instId,
    required this.holdSide,
    required this.total,
    required this.openPriceAvg,
    required this.markPrice,
    required this.unrealizedPL,
    required this.leverage,
    required this.cTime,
    required this.totalFee,
    required this.deductedFee,
  });

  /// The instrument id, tolerating either REST (`symbol`) or WS (`instId`).
  String get instrument => symbol.isNotEmpty ? symbol : instId;

  factory PositionDto.fromJson(Map<String, Object?> json) =>
      _$PositionDtoFromJson(json);
}
