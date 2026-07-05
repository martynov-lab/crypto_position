import 'package:json_annotation/json_annotation.dart';

part 'wallet_balance_dto.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class WalletBalanceDto {
  final String accountType;
  final String totalEquity;
  final String totalWalletBalance;
  @JsonKey(name: 'coin')
  final List<CoinBalanceDto> coins;

  const WalletBalanceDto({
    required this.accountType,
    required this.totalEquity,
    required this.totalWalletBalance,
    required this.coins,
  });

  factory WalletBalanceDto.fromJson(Map<String, Object?> json) =>
      _$WalletBalanceDtoFromJson(json);
}

@JsonSerializable(checked: true, createToJson: false)
class CoinBalanceDto {
  final String coin;
  final String equity;
  final String walletBalance;
  final String usdValue;
  final String unrealisedPnl;

  const CoinBalanceDto({
    required this.coin,
    required this.equity,
    required this.walletBalance,
    required this.usdValue,
    required this.unrealisedPnl,
  });

  factory CoinBalanceDto.fromJson(Map<String, Object?> json) =>
      _$CoinBalanceDtoFromJson(json);
}
