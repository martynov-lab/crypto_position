import 'package:json_annotation/json_annotation.dart';

part 'funding_rate_dto.g.dart';

/// Public `funding-rate` channel payload.
///
/// [fundingRate] is the rate that settles at [fundingTime] — the upcoming
/// settlement. OKX also sends `nextFundingRate`/`nextFundingTime` for the one
/// after that, which is only a forecast and is deliberately not parsed here.
@JsonSerializable(checked: true, createToJson: false)
class FundingRateDto {
  @JsonKey(defaultValue: '')
  final String instId;

  /// Rate as a fraction ('0.0001' = 0.01%).
  final String? fundingRate;

  /// Epoch milliseconds of the settlement [fundingRate] applies to.
  final String? fundingTime;

  const FundingRateDto({
    required this.instId,
    this.fundingRate,
    this.fundingTime,
  });

  factory FundingRateDto.fromJson(Map<String, Object?> json) =>
      _$FundingRateDtoFromJson(json);
}
