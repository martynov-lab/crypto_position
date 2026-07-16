// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GateAccountDto _$GateAccountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GateAccountDto', json, ($checkedConvert) {
      final val = GateAccountDto(
        user: $checkedConvert('user', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });
