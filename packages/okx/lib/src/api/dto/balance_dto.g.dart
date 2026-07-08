// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceDto _$BalanceDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BalanceDto',
  json,
  ($checkedConvert) {
    final val = BalanceDto(
      totalEq: $checkedConvert('totalEq', (v) => v as String? ?? '0'),
      details: $checkedConvert(
        'details',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => CoinBalanceDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      ),
    );
    return val;
  },
);

CoinBalanceDto _$CoinBalanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CoinBalanceDto', json, ($checkedConvert) {
      final val = CoinBalanceDto(
        ccy: $checkedConvert('ccy', (v) => v as String? ?? ''),
        eq: $checkedConvert('eq', (v) => v as String? ?? '0'),
        cashBal: $checkedConvert('cashBal', (v) => v as String? ?? '0'),
        eqUsd: $checkedConvert('eqUsd', (v) => v as String? ?? '0'),
        upl: $checkedConvert('upl', (v) => v as String? ?? '0'),
      );
      return val;
    });
