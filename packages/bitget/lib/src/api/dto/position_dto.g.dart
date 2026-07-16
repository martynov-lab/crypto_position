// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionDto _$PositionDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PositionDto',
  json,
  ($checkedConvert) {
    final val = PositionDto(
      symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
      instId: $checkedConvert('instId', (v) => v as String? ?? ''),
      holdSide: $checkedConvert('holdSide', (v) => v as String? ?? ''),
      total: $checkedConvert('total', (v) => v as String? ?? '0'),
      openPriceAvg: $checkedConvert('openPriceAvg', (v) => v as String? ?? '0'),
      markPrice: $checkedConvert('markPrice', (v) => v as String? ?? '0'),
      unrealizedPL: $checkedConvert('unrealizedPL', (v) => v as String? ?? '0'),
      leverage: $checkedConvert('leverage', (v) => v as String? ?? '0'),
      cTime: $checkedConvert('cTime', (v) => v as String? ?? ''),
      totalFee: $checkedConvert('totalFee', (v) => v as String? ?? ''),
      deductedFee: $checkedConvert('deductedFee', (v) => v as String? ?? ''),
    );
    return val;
  },
);
