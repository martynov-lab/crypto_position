// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionDto _$PositionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PositionDto', json, ($checkedConvert) {
      final val = PositionDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        side: $checkedConvert('side', (v) => v as String? ?? ''),
        size: $checkedConvert('size', (v) => v as String? ?? '0'),
        avgPrice: $checkedConvert('avgPrice', (v) => v as String? ?? '0'),
        entryPrice: $checkedConvert('entryPrice', (v) => v as String? ?? '0'),
        markPrice: $checkedConvert('markPrice', (v) => v as String? ?? '0'),
        unrealisedPnl: $checkedConvert(
          'unrealisedPnl',
          (v) => v as String? ?? '0',
        ),
        leverage: $checkedConvert('leverage', (v) => v as String? ?? '0'),
        positionIdx: $checkedConvert(
          'positionIdx',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        createdTime: $checkedConvert('createdTime', (v) => v as String? ?? ''),
      );
      return val;
    });
