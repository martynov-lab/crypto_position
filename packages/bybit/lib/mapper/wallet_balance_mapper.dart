import '../domain/models/wallet_balance.dart';
import '../dto/coin_balance_dto.dart';
import '../dto/wallet_balance_dto.dart';

class WalletBalanceMapper {
  WalletBalance fromDto(WalletBalanceDto dto) {
    return WalletBalance(
      accountType: dto.accountType,
      totalEquity: double.tryParse(dto.totalEquity) ?? 0,
      totalWalletBalance: double.tryParse(dto.totalWalletBalance) ?? 0,
      coins: dto.coins.map(_coinFromDto).toList(),
    );
  }

  CoinBalance _coinFromDto(CoinBalanceDto dto) {
    return CoinBalance(
      coin: dto.coin,
      walletBalance: double.tryParse(dto.walletBalance) ?? 0,
      availableToWithdraw: double.tryParse(dto.availableToWithdraw) ?? 0,
      unrealisedPnl: double.tryParse(dto.unrealisedPnl) ?? 0,
    );
  }
}
