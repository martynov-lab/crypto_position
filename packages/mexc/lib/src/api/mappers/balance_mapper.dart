import 'package:exchange/exchange.dart';

import '../dto/balance_dto.dart';

extension MexcBalanceMapper on MexcBalanceDto {
  BalanceModel toModel() {
    final coins = assets.map((asset) => asset.toModel()).toList();
    // The account holds margin per currency; the exchange-agnostic total is the
    // USDT equity (MEXC futures are USDT-margined). Fall back to the first
    // asset's equity if there is no USDT entry.
    final usdt = assets.where((a) => a.currency == 'USDT');
    final total = usdt.isNotEmpty
        ? usdt.first.equity.toDouble()
        : (coins.isNotEmpty ? coins.first.equity : 0.0);
    return BalanceModel(
      totalEquity: total,
      totalWalletBalance: total,
      coins: coins,
    );
  }
}

extension AssetMapper on AssetDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: currency,
        equity: equity.toDouble(),
        walletBalance: availableBalance.toDouble(),
        usdValue: equity.toDouble(),
        unrealisedPnl: unrealized.toDouble(),
      );
}
