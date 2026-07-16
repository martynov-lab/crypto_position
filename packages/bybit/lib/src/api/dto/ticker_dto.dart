import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `tickers.{symbol}` topic payload.
///
/// Delta frames contain only changed fields, so [markPrice], [fundingRate] and
/// [nextFundingTime] are nullable: a tick without one must be skipped instead
/// of read as zero.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  final String? markPrice;

  /// Rate for the upcoming settlement, as a fraction ('0.0001' = 0.01%).
  final String? fundingRate;

  /// Epoch milliseconds of the next settlement, as a string.
  final String? nextFundingTime;

  const TickerDto({
    required this.symbol,
    this.markPrice,
    this.fundingRate,
    this.nextFundingTime,
  });

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
