// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetDto _$AssetDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AssetDto', json, ($checkedConvert) {
      final val = AssetDto(
        currency: $checkedConvert('currency', (v) => v as String? ?? ''),
        equity: $checkedConvert('equity', (v) => v as num? ?? 0),
        availableBalance: $checkedConvert(
          'availableBalance',
          (v) => v as num? ?? 0,
        ),
        cashBalance: $checkedConvert('cashBalance', (v) => v as num? ?? 0),
        unrealized: $checkedConvert('unrealized', (v) => v as num? ?? 0),
      );
      return val;
    });
