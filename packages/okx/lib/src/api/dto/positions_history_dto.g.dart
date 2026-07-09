// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'positions_history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionsHistoryDto _$PositionsHistoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PositionsHistoryDto', json, ($checkedConvert) {
      final val = PositionsHistoryDto(
        instId: $checkedConvert('instId', (v) => v as String? ?? ''),
        posId: $checkedConvert('posId', (v) => v as String? ?? ''),
        direction: $checkedConvert('direction', (v) => v as String? ?? ''),
        lever: $checkedConvert('lever', (v) => v as String? ?? '0'),
        openAvgPx: $checkedConvert('openAvgPx', (v) => v as String? ?? '0'),
        closeAvgPx: $checkedConvert('closeAvgPx', (v) => v as String? ?? '0'),
        closeTotalPos: $checkedConvert(
          'closeTotalPos',
          (v) => v as String? ?? '0',
        ),
        realizedPnl: $checkedConvert('realizedPnl', (v) => v as String? ?? '0'),
        cTime: $checkedConvert('cTime', (v) => v as String? ?? '0'),
        uTime: $checkedConvert('uTime', (v) => v as String? ?? '0'),
      );
      return val;
    });
