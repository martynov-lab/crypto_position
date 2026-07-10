import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `ticker` channel payload, used to re-price open positions for live
/// PnL. [markPrice] is nullable because delta frames may omit it.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String instId;
  final String? markPrice;

  const TickerDto({required this.instId, this.markPrice});

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
