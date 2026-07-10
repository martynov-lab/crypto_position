// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TickerDto _$TickerDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TickerDto', json, ($checkedConvert) {
      final val = TickerDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        fairPrice: $checkedConvert('fairPrice', (v) => v as num?),
      );
      return val;
    });
