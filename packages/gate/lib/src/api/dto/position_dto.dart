import 'package:json_annotation/json_annotation.dart';

part 'position_dto.g.dart';

/// Open position from REST `/futures/usdt/positions` or the private
/// `futures.positions` WebSocket channel.
///
/// [size] is the signed number of contracts (negative for a short). [value] is
/// the position value in the settlement currency, so the base quantity is
/// `|value| / markPrice` (independent of the mark). [leverage] is `"0"` for
/// cross margin.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class PositionDto {
  @JsonKey(defaultValue: '')
  final String contract;
  @JsonKey(defaultValue: 0)
  final int size;
  @JsonKey(defaultValue: '0')
  final String leverage;
  @JsonKey(defaultValue: '0')
  final String entryPrice;
  @JsonKey(defaultValue: '0')
  final String markPrice;
  @JsonKey(defaultValue: '0')
  final String unrealisedPnl;
  @JsonKey(defaultValue: '0')
  final String value;

  const PositionDto({
    required this.contract,
    required this.size,
    required this.leverage,
    required this.entryPrice,
    required this.markPrice,
    required this.unrealisedPnl,
    required this.value,
  });

  factory PositionDto.fromJson(Map<String, Object?> json) =>
      _$PositionDtoFromJson(json);
}
