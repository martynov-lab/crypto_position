// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TickerDto _$TickerDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TickerDto',
  json,
  ($checkedConvert) {
    final val = TickerDto(
      contract: $checkedConvert('contract', (v) => v as String? ?? ''),
      markPrice: $checkedConvert('mark_price', (v) => v as String?),
      fundingRate: $checkedConvert('funding_rate', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'markPrice': 'mark_price', 'fundingRate': 'funding_rate'},
);
