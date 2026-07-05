// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletBalanceDto _$WalletBalanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WalletBalanceDto', json, ($checkedConvert) {
      final val = WalletBalanceDto(
        accountType: $checkedConvert('accountType', (v) => v as String),
        totalEquity: $checkedConvert('totalEquity', (v) => v as String),
        totalWalletBalance: $checkedConvert(
          'totalWalletBalance',
          (v) => v as String,
        ),
        coins: $checkedConvert(
          'coin',
          (v) => (v as List<dynamic>)
              .map((e) => CoinBalanceDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'coins': 'coin'});

CoinBalanceDto _$CoinBalanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CoinBalanceDto', json, ($checkedConvert) {
      final val = CoinBalanceDto(
        coin: $checkedConvert('coin', (v) => v as String),
        equity: $checkedConvert('equity', (v) => v as String),
        walletBalance: $checkedConvert('walletBalance', (v) => v as String),
        usdValue: $checkedConvert('usdValue', (v) => v as String),
        unrealisedPnl: $checkedConvert('unrealisedPnl', (v) => v as String),
      );
      return val;
    });
