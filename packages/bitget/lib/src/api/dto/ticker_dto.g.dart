// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TickerDto _$TickerDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TickerDto', json, ($checkedConvert) {
      final val = TickerDto(
        instId: $checkedConvert('instId', (v) => v as String? ?? ''),
        markPrice: $checkedConvert('markPrice', (v) => v as String?),
      );
      return val;
    });
