// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BitgetAccountDto _$BitgetAccountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BitgetAccountDto', json, ($checkedConvert) {
      final val = BitgetAccountDto(
        marginCoin: $checkedConvert('marginCoin', (v) => v as String? ?? ''),
        usdtEquity: $checkedConvert('usdtEquity', (v) => v as String? ?? '0'),
        available: $checkedConvert('available', (v) => v as String? ?? '0'),
        unrealizedPL: $checkedConvert(
          'unrealizedPL',
          (v) => v as String? ?? '0',
        ),
      );
      return val;
    });
