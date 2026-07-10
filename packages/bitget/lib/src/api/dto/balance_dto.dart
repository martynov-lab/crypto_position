import 'package:json_annotation/json_annotation.dart';

part 'balance_dto.g.dart';

/// One account entry from REST `/api/v2/mix/account/accounts` or the private
/// `account` WebSocket channel. For USDT-FUTURES there is a single USDT margin
/// account. Fields common to both REST and WS are used so one DTO serves both.
@JsonSerializable(checked: true, createToJson: false)
class BitgetAccountDto {
  @JsonKey(defaultValue: '')
  final String marginCoin;

  /// Account equity valued in USDT — the exchange-agnostic "total" for the
  /// account (Bitget has no separate wallet-balance total).
  @JsonKey(defaultValue: '0')
  final String usdtEquity;

  /// Available (free) balance.
  @JsonKey(defaultValue: '0')
  final String available;

  @JsonKey(defaultValue: '0')
  final String unrealizedPL;

  const BitgetAccountDto({
    required this.marginCoin,
    required this.usdtEquity,
    required this.available,
    required this.unrealizedPL,
  });

  factory BitgetAccountDto.fromJson(Map<String, Object?> json) =>
      _$BitgetAccountDtoFromJson(json);
}

/// Aggregate of every [BitgetAccountDto] returned by the balance endpoint (the
/// REST `data` array), constructed manually since that array is unwrapped.
class BitgetBalanceDto {
  final List<BitgetAccountDto> accounts;

  const BitgetBalanceDto(this.accounts);
}
