import 'package:json_annotation/json_annotation.dart';

part 'balance_dto.g.dart';

/// One asset entry from REST `/private/account/assets` or the private
/// `push.personal.asset` WebSocket channel. Amounts are per-currency in that
/// currency's own units (MEXC sends them as JSON numbers).
@JsonSerializable(checked: true, createToJson: false)
class AssetDto {
  @JsonKey(defaultValue: '')
  final String currency;
  @JsonKey(defaultValue: 0)
  final num equity;
  @JsonKey(defaultValue: 0)
  final num availableBalance;
  @JsonKey(defaultValue: 0)
  final num cashBalance;
  @JsonKey(defaultValue: 0)
  final num unrealized;

  const AssetDto({
    required this.currency,
    required this.equity,
    required this.availableBalance,
    required this.cashBalance,
    required this.unrealized,
  });

  factory AssetDto.fromJson(Map<String, Object?> json) =>
      _$AssetDtoFromJson(json);
}

/// Aggregate of every [AssetDto] the account holds (the REST `data` array),
/// constructed manually since that array is unwrapped.
class MexcBalanceDto {
  final List<AssetDto> assets;

  const MexcBalanceDto(this.assets);
}
