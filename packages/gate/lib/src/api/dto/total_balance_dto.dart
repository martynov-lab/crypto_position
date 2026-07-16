import 'package:json_annotation/json_annotation.dart';

part 'total_balance_dto.g.dart';

/// REST `/wallet/total_balance`: every Gate wallet (spot, futures, margin,
/// earn) summed and converted into a single currency by the exchange.
///
/// This is the only Gate endpoint that reports a whole-account total. The
/// per-wallet endpoints each cover one wallet and report raw coin amounts, so
/// adding them up would mean fetching prices and converting by hand.
///
/// Requires wallet read permission on the API key.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class TotalBalanceDto {
  final TotalBalanceAmountDto total;

  const TotalBalanceDto({required this.total});

  factory TotalBalanceDto.fromJson(Map<String, Object?> json) =>
      _$TotalBalanceDtoFromJson(json);
}

/// The converted total. [unrealisedPnl] covers the futures wallet only.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class TotalBalanceAmountDto {
  @JsonKey(defaultValue: 'USDT')
  final String currency;
  @JsonKey(defaultValue: '0')
  final String amount;
  @JsonKey(defaultValue: '0')
  final String unrealisedPnl;

  const TotalBalanceAmountDto({
    required this.currency,
    required this.amount,
    required this.unrealisedPnl,
  });

  factory TotalBalanceAmountDto.fromJson(Map<String, Object?> json) =>
      _$TotalBalanceAmountDtoFromJson(json);
}
