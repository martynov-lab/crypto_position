import 'coin_balance_dto.dart';

class WalletBalanceDto {
  final String accountType;
  final String totalEquity;
  final String totalWalletBalance;
  final List<CoinBalanceDto> coins;

  WalletBalanceDto({
    required this.accountType,
    required this.totalEquity,
    required this.totalWalletBalance,
    required this.coins,
  });

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) {
    final coinList =
        (json['coin'] as List<dynamic>?)
            ?.map((e) => CoinBalanceDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return WalletBalanceDto(
      accountType: json['accountType'] as String? ?? '',
      totalEquity: '${json['totalEquity'] ?? '0'}',
      totalWalletBalance: '${json['totalWalletBalance'] ?? '0'}',
      coins: coinList,
    );
  }
}
