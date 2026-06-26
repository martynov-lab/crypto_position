class CoinBalance {
  final String coin;
  final double walletBalance;
  final double availableToWithdraw;
  final double unrealisedPnl;

  CoinBalance({
    required this.coin,
    required this.walletBalance,
    required this.availableToWithdraw,
    required this.unrealisedPnl,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      coin: json['coin'] as String? ?? '',
      walletBalance: double.tryParse('${json['walletBalance']}') ?? 0,
      availableToWithdraw:
          double.tryParse('${json['availableToWithdraw']}') ?? 0,
      unrealisedPnl: double.tryParse('${json['unrealisedPnl']}') ?? 0,
    );
  }
}

class WalletBalance {
  final String accountType;
  final double totalEquity;
  final double totalWalletBalance;
  final List<CoinBalance> coins;

  WalletBalance({
    required this.accountType,
    required this.totalEquity,
    required this.totalWalletBalance,
    required this.coins,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final coinList = (json['coin'] as List<dynamic>?)
            ?.map((e) => CoinBalance.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return WalletBalance(
      accountType: json['accountType'] as String? ?? '',
      totalEquity: double.tryParse('${json['totalEquity']}') ?? 0,
      totalWalletBalance:
          double.tryParse('${json['totalWalletBalance']}') ?? 0,
      coins: coinList,
    );
  }
}
