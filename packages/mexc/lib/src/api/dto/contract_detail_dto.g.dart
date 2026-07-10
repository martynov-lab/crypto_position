// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractDetailDto _$ContractDetailDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ContractDetailDto', json, ($checkedConvert) {
      final val = ContractDetailDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        contractSize: $checkedConvert('contractSize', (v) => v as num? ?? 0),
      );
      return val;
    });
