// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionDto _$PositionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PositionDto', json, ($checkedConvert) {
      final val = PositionDto(
        instId: $checkedConvert('instId', (v) => v as String? ?? ''),
        posSide: $checkedConvert('posSide', (v) => v as String? ?? ''),
        pos: $checkedConvert('pos', (v) => v as String? ?? '0'),
        avgPx: $checkedConvert('avgPx', (v) => v as String? ?? '0'),
        markPx: $checkedConvert('markPx', (v) => v as String? ?? '0'),
        upl: $checkedConvert('upl', (v) => v as String? ?? '0'),
        lever: $checkedConvert('lever', (v) => v as String? ?? '0'),
      );
      return val;
    });
