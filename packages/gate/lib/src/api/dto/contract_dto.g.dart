// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractDto _$ContractDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ContractDto', json, ($checkedConvert) {
      final val = ContractDto(
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        fundingNextApply: $checkedConvert(
          'funding_next_apply',
          (v) => v as num? ?? 0,
        ),
      );
      return val;
    }, fieldKeyMap: const {'fundingNextApply': 'funding_next_apply'});
