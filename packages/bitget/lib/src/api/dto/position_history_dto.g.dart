// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionHistoryDto _$PositionHistoryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PositionHistoryDto', json, ($checkedConvert) {
  final val = PositionHistoryDto(
    symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
    holdSide: $checkedConvert('holdSide', (v) => v as String? ?? ''),
    openAvgPrice: $checkedConvert('openAvgPrice', (v) => v as String? ?? '0'),
    closeAvgPrice: $checkedConvert('closeAvgPrice', (v) => v as String? ?? '0'),
    closeTotalPos: $checkedConvert('closeTotalPos', (v) => v as String? ?? '0'),
    netProfit: $checkedConvert('netProfit', (v) => v as String? ?? '0'),
    leverage: $checkedConvert('leverage', (v) => v as String? ?? '0'),
    ctime: $checkedConvert('ctime', (v) => v as String? ?? '0'),
    utime: $checkedConvert('utime', (v) => v as String? ?? '0'),
  );
  return val;
});
