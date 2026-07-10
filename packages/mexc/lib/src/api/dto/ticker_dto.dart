import 'package:json_annotation/json_annotation.dart';

part 'ticker_dto.g.dart';

/// Public ticker from REST `/contract/ticker` or the `push.ticker` channel.
/// [fairPrice] is the mark price used to re-price open positions for live PnL.
@JsonSerializable(checked: true, createToJson: false)
class TickerDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  final num? fairPrice;

  const TickerDto({required this.symbol, this.fairPrice});

  factory TickerDto.fromJson(Map<String, Object?> json) =>
      _$TickerDtoFromJson(json);
}
