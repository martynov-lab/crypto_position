import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `ticker` channel payload, used to re-price open positions for live
/// PnL and to read the upcoming funding. All three value fields are nullable
/// because delta frames may omit them.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String instId;
  final String? markPrice;

  /// Rate for the upcoming settlement, as a fraction ('0.0001' = 0.01%).
  final String? fundingRate;

  /// Epoch milliseconds of the next settlement, as a string.
  final String? nextFundingTime;

  const TickerDto({
    required this.instId,
    this.markPrice,
    this.fundingRate,
    this.nextFundingTime,
  });

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
