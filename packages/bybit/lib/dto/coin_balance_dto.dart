class CoinBalanceDto {
  final String coin;
  final String walletBalance;
  final String availableToWithdraw;
  final String unrealisedPnl;

  CoinBalanceDto({
    required this.coin,
    required this.walletBalance,
    required this.availableToWithdraw,
    required this.unrealisedPnl,
  });

  factory CoinBalanceDto.fromJson(Map<String, dynamic> json) {
    return CoinBalanceDto(
      coin: json['coin'] as String? ?? '',
      walletBalance: '${json['walletBalance'] ?? '0'}',
      availableToWithdraw: '${json['availableToWithdraw'] ?? '0'}',
      unrealisedPnl: '${json['unrealisedPnl'] ?? '0'}',
    );
  }
}
