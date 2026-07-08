import 'package:exchange/exchange.dart';

import '../dto/wallet_balance_dto.dart';

extension WalletBalanceMapper on WalletBalanceDto {
  BalanceModel toModel() => BalanceModel(
        totalEquity: _parseAmount(totalEquity),
        totalWalletBalance: _parseAmount(totalWalletBalance),
        coins: coins.map((coin) => coin.toModel()).toList(),
      );
}

extension CoinBalanceMapper on CoinBalanceDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: coin,
        equity: _parseAmount(equity),
        walletBalance: _parseAmount(walletBalance),
        usdValue: _parseAmount(usdValue),
        unrealisedPnl: _parseAmount(unrealisedPnl),
      );
}

/// Bybit returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
