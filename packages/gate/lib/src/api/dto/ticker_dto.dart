import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public `futures.tickers` payload, used to re-price open positions for live
/// PnL and to read the funding rate. Both value fields are nullable because
/// not every tick carries them.
///
/// The ticker has no next-settlement time; that lives on the contracts REST
/// endpoint (`funding_next_apply`), which the repository reads separately.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String contract;
  final String? markPrice;

  /// Rate for the upcoming settlement, as a fraction ('0.0001' = 0.01%).
  final String? fundingRate;

  const TickerDto({
    required this.contract,
    this.markPrice,
    this.fundingRate,
  });

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
