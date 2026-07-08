import 'package:json_annotation/json_annotation.dart';

part 'mark_price_dto.g.dart';

/// Public `mark-price` channel payload, used to re-price open positions for
/// live PnL (the OKX analog of Bybit's `tickers` mark price).
@JsonSerializable(checked: true, createToJson: false)
class MarkPriceDto {
  @JsonKey(defaultValue: '')
  final String instId;
  final String? markPx;

  const MarkPriceDto({required this.instId, this.markPx});

  factory MarkPriceDto.fromJson(Map<String, Object?> json) =>
      _$MarkPriceDtoFromJson(json);
}
