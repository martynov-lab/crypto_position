// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_price_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkPriceDto _$MarkPriceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MarkPriceDto', json, ($checkedConvert) {
      final val = MarkPriceDto(
        instId: $checkedConvert('instId', (v) => v as String? ?? ''),
        markPx: $checkedConvert('markPx', (v) => v as String?),
      );
      return val;
    });
