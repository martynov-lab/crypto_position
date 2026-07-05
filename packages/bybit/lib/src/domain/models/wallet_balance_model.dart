import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_balance_model.freezed.dart';

@freezed
abstract class WalletBalanceModel with _$WalletBalanceModel {
  const factory WalletBalanceModel({
    required String accountType,
    required double totalEquity,
    required double totalWalletBalance,
    required List<CoinBalanceModel> coins,
  }) = _WalletBalanceModel;
}

@freezed
abstract class CoinBalanceModel with _$CoinBalanceModel {
  const factory CoinBalanceModel({
    required String coin,
    required double equity,
    required double walletBalance,
    required double usdValue,
    required double unrealisedPnl,
  }) = _CoinBalanceModel;
}
