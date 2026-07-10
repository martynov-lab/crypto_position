import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `futures.tickers` payload, used to re-price open positions for live
/// PnL. [markPrice] is nullable because not every tick carries it.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String contract;
  final String? markPrice;

  const TickerDto({required this.contract, this.markPrice});

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
