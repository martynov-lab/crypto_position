// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionDto _$PositionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PositionDto', json, ($checkedConvert) {
      final val = PositionDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        holdVol: $checkedConvert('holdVol', (v) => v as num? ?? 0),
        holdAvgPrice: $checkedConvert('holdAvgPrice', (v) => v as num? ?? 0),
        positionType: $checkedConvert(
          'positionType',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        leverage: $checkedConvert('leverage', (v) => v as num? ?? 0),
        state: $checkedConvert('state', (v) => (v as num?)?.toInt() ?? 1),
        createTime: $checkedConvert('createTime', (v) => v as num?),
        holdFee: $checkedConvert('holdFee', (v) => v as num?),
      );
      return val;
    });
