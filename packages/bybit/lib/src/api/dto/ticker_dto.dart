import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `tickers.{symbol}` topic payload.
///
/// Delta frames contain only changed fields, so [markPrice] is nullable:
/// a tick without it must be skipped instead of read as zero.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  final String? markPrice;

  const TickerDto({required this.symbol, this.markPrice});

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
