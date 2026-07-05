// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'closed_pnl_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClosedPnlDto _$ClosedPnlDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClosedPnlDto', json, ($checkedConvert) {
  final val = ClosedPnlDto(
    symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
    orderId: $checkedConvert('orderId', (v) => v as String? ?? ''),
    side: $checkedConvert('side', (v) => v as String? ?? ''),
    qty: $checkedConvert('qty', (v) => v as String? ?? '0'),
    orderPrice: $checkedConvert('orderPrice', (v) => v as String? ?? '0'),
    orderType: $checkedConvert('orderType', (v) => v as String? ?? ''),
    avgEntryPrice: $checkedConvert('avgEntryPrice', (v) => v as String? ?? '0'),
    avgExitPrice: $checkedConvert('avgExitPrice', (v) => v as String? ?? '0'),
    closedPnl: $checkedConvert('closedPnl', (v) => v as String? ?? '0'),
    leverage: $checkedConvert('leverage', (v) => v as String? ?? '0'),
    cumEntryValue: $checkedConvert('cumEntryValue', (v) => v as String? ?? '0'),
    cumExitValue: $checkedConvert('cumExitValue', (v) => v as String? ?? '0'),
    createdTime: $checkedConvert('createdTime', (v) => v as String? ?? '0'),
    updatedTime: $checkedConvert('updatedTime', (v) => v as String? ?? '0'),
  );
  return val;
});
