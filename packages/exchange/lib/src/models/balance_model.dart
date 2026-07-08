import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_model.freezed.dart';

/// Exchange-agnostic account balance. Every exchange maps its own payload to
/// this shape so the app consumes all of them uniformly.
@freezed
abstract class BalanceModel with _$BalanceModel {
  const factory BalanceModel({
    required double totalEquity,
    required double totalWalletBalance,
    required List<CoinBalanceModel> coins,
  }) = _BalanceModel;
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
