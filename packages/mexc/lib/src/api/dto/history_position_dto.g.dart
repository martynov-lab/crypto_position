// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryPositionDto _$HistoryPositionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HistoryPositionDto', json, ($checkedConvert) {
      final val = HistoryPositionDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        positionType: $checkedConvert(
          'positionType',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        openAvgPrice: $checkedConvert('openAvgPrice', (v) => v as num? ?? 0),
        closeAvgPrice: $checkedConvert('closeAvgPrice', (v) => v as num? ?? 0),
        closeVol: $checkedConvert('closeVol', (v) => v as num? ?? 0),
        realised: $checkedConvert('realised', (v) => v as num? ?? 0),
        leverage: $checkedConvert('leverage', (v) => v as num? ?? 0),
        updateTime: $checkedConvert('updateTime', (v) => v as num? ?? 0),
      );
      return val;
    });
