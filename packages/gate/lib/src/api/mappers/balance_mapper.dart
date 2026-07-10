import 'package:exchange/exchange.dart';

import '../dto/balance_dto.dart';

extension GateBalanceMapper on GateAccountDto {
  BalanceModel toModel() {
    // Gate futures account totals are already in USDT. There is no separate
    // wallet-balance total, so total equity is the closest equivalent for both.
    final totalEquity = _parseAmount(total);
    return BalanceModel(
      totalEquity: totalEquity,
      totalWalletBalance: totalEquity,
      coins: [
        CoinBalanceModel(
          coin: currency,
          equity: totalEquity,
          walletBalance: _parseAmount(available),
          usdValue: totalEquity,
          unrealisedPnl: _parseAmount(unrealisedPnl),
        ),
      ],
    );
  }
}

/// Gate returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
