import 'package:exchange/exchange.dart';

import '../dto/total_balance_dto.dart';

extension GateTotalBalanceMapper on TotalBalanceDto {
  BalanceModel toModel() {
    // Gate already converted every wallet into one currency, so the total needs
    // no per-coin arithmetic. It reports no separate equity, so the converted
    // amount stands for both.
    final amount = _parseAmount(total.amount);
    return BalanceModel(
      totalEquity: amount,
      totalWalletBalance: amount,
      coins: [
        CoinBalanceModel(
          coin: total.currency,
          equity: amount,
          walletBalance: amount,
          usdValue: amount,
          unrealisedPnl: _parseAmount(total.unrealisedPnl),
        ),
      ],
    );
  }
}

/// Gate returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
