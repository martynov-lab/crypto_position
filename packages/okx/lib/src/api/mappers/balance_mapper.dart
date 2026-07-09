import 'package:exchange/exchange.dart';

import '../dto/balance_dto.dart';

extension BalanceMapper on BalanceDto {
  BalanceModel toModel() {
    final coins = details.map((coin) => coin.toModel()).toList();
    // OKX only populates `totalEq` in unified/margin account modes; in Spot
    // (simple) mode it stays "0" even with funds, so fall back to the sum of
    // per-coin USD equity. OKX also has no separate "wallet balance" total, so
    // total equity is the closest exchange-agnostic equivalent.
    final totalEquity = _parseAmount(totalEq);
    final total = totalEquity != 0
        ? totalEquity
        : coins.fold<double>(0, (sum, coin) => sum + coin.usdValue);
    return BalanceModel(
      totalEquity: total,
      totalWalletBalance: total,
      coins: coins,
    );
  }
}

extension CoinBalanceMapper on CoinBalanceDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: ccy,
        equity: _parseAmount(eq),
        // OKX reports cash balance as `cashBal`.
        walletBalance: _parseAmount(cashBal),
        usdValue: _parseAmount(eqUsd),
        unrealisedPnl: _parseAmount(upl),
      );
}

/// OKX returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
