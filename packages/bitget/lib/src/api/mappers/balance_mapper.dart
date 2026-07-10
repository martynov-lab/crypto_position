import 'package:exchange/exchange.dart';

import '../dto/balance_dto.dart';

extension BitgetBalanceMapper on BitgetBalanceDto {
  BalanceModel toModel() {
    final coins = accounts.map((account) => account.toModel()).toList();
    // Bitget has no separate wallet-balance total, so USDT equity (summed over
    // margin accounts) is the closest exchange-agnostic equivalent for both.
    final total = coins.fold<double>(0, (sum, coin) => sum + coin.usdValue);
    return BalanceModel(
      totalEquity: total,
      totalWalletBalance: total,
      coins: coins,
    );
  }
}

extension BitgetAccountMapper on BitgetAccountDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: marginCoin,
        equity: _parseAmount(usdtEquity),
        walletBalance: _parseAmount(available),
        usdValue: _parseAmount(usdtEquity),
        unrealisedPnl: _parseAmount(unrealizedPL),
      );
}

/// Bitget returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
