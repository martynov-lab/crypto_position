import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public ticker from REST `/contract/ticker` or the `push.ticker` channel.
/// [fairPrice] is the mark price used to re-price open positions for live PnL.
///
/// The ticker has no next-settlement time; that comes from the funding-rate
/// endpoint, which the repository reads separately.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  final num? fairPrice;

  /// Rate for the upcoming settlement, as a fraction (0.0001 = 0.01%).
  final num? fundingRate;

  const TickerDto({required this.symbol, this.fairPrice, this.fundingRate});

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
