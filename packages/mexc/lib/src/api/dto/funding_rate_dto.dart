import 'package:json_annotation/json_annotation.dart';

part 'funding_rate_dto.g.dart';

/// Public `/contract/funding_rate/{symbol}` payload.
///
/// MEXC's ticker carries the rate but not the schedule, so this supplies
/// [nextSettleTime]. Unlike every other endpoint here it returns a single
/// object rather than a list.
@JsonSerializable(checked: true, createToJson: false)
class FundingRateDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  final num? fundingRate;

  /// Epoch milliseconds of the next settlement.
  final num? nextSettleTime;

  const FundingRateDto({
    required this.symbol,
    this.fundingRate,
    this.nextSettleTime,
  });

  factory FundingRateDto.fromJson(Map<String, Object?> json) =>
      _$FundingRateDtoFromJson(json);
}
