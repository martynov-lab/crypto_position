class CoinBalance {
  final String coin;
  final double walletBalance;
  final double availableToWithdraw;
  final double unrealisedPnl;

  const CoinBalance({
    required this.coin,
    required this.walletBalance,
    required this.availableToWithdraw,
    required this.unrealisedPnl,
  });
}

class WalletBalance {
  final String accountType;
  final double totalEquity;
  final double totalWalletBalance;
  final List<CoinBalance> coins;

  const WalletBalance({
    required this.accountType,
    required this.totalEquity,
    required this.totalWalletBalance,
    required this.coins,
  });
}
