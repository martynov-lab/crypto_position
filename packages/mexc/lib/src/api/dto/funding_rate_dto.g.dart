// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funding_rate_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FundingRateDto _$FundingRateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FundingRateDto', json, ($checkedConvert) {
      final val = FundingRateDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        fundingRate: $checkedConvert('fundingRate', (v) => v as num?),
        nextSettleTime: $checkedConvert('nextSettleTime', (v) => v as num?),
      );
      return val;
    });
