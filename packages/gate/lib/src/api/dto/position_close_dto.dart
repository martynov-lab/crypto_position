import 'package:json_annotation/json_annotation.dart';

part 'position_close_dto.g.dart';

/// One closed position from REST `/futures/usdt/position_close`.
///
/// [time] is the close time in **seconds** (may be fractional). [side] is the
/// closed position's direction (`long`/`short`). [longPrice] is the long open /
/// short close price, [shortPrice] the short open / long close price.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class PositionCloseDto {
  @JsonKey(defaultValue: 0)
  final num time;
  @JsonKey(defaultValue: '')
  final String contract;
  @JsonKey(defaultValue: '')
  final String side;
  @JsonKey(defaultValue: '0')
  final String pnl;
  @JsonKey(defaultValue: '0')
  final String accumSize;
  @JsonKey(defaultValue: '0')
  final String longPrice;
  @JsonKey(defaultValue: '0')
  final String shortPrice;

  const PositionCloseDto({
    required this.time,
    required this.contract,
    required this.side,
    required this.pnl,
    required this.accumSize,
    required this.longPrice,
    required this.shortPrice,
  });

  factory PositionCloseDto.fromJson(Map<String, Object?> json) =>
      _$PositionCloseDtoFromJson(json);
}
