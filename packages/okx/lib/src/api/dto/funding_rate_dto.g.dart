// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funding_rate_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FundingRateDto _$FundingRateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FundingRateDto', json, ($checkedConvert) {
      final val = FundingRateDto(
        instId: $checkedConvert('instId', (v) => v as String? ?? ''),
        fundingRate: $checkedConvert('fundingRate', (v) => v as String?),
        fundingTime: $checkedConvert('fundingTime', (v) => v as String?),
      );
      return val;
    });
