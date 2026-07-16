// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalBalanceDto _$TotalBalanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TotalBalanceDto', json, ($checkedConvert) {
      final val = TotalBalanceDto(
        total: $checkedConvert(
          'total',
          (v) => TotalBalanceAmountDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

TotalBalanceAmountDto _$TotalBalanceAmountDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TotalBalanceAmountDto',
  json,
  ($checkedConvert) {
    final val = TotalBalanceAmountDto(
      currency: $checkedConvert('currency', (v) => v as String? ?? 'USDT'),
      amount: $checkedConvert('amount', (v) => v as String? ?? '0'),
      unrealisedPnl: $checkedConvert(
        'unrealised_pnl',
        (v) => v as String? ?? '0',
      ),
    );
    return val;
  },
  fieldKeyMap: const {'unrealisedPnl': 'unrealised_pnl'},
);
