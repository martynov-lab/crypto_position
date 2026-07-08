import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_model.freezed.dart';

@freezed
abstract class BalanceModel with _$BalanceModel {
  const factory BalanceModel({
    required double totalEquity,
    required List<CoinBalanceModel> coins,
  }) = _BalanceModel;
}

@freezed
abstract class CoinBalanceModel with _$CoinBalanceModel {
  const factory CoinBalanceModel({
    required String coin,
    required double equity,
    required double cashBalance,
    required double usdValue,
    required double unrealisedPnl,
  }) = _CoinBalanceModel;
}
