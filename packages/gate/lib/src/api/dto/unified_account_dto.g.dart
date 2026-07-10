// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedAccountDto _$UnifiedAccountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UnifiedAccountDto',
      json,
      ($checkedConvert) {
        final val = UnifiedAccountDto(
          userId: $checkedConvert('user_id', (v) => (v as num?)?.toInt() ?? 0),
          total: $checkedConvert('total', (v) => v as String? ?? '0'),
          unifiedAccountTotalEquity: $checkedConvert(
            'unified_account_total_equity',
            (v) => v as String? ?? '0',
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'unifiedAccountTotalEquity': 'unified_account_total_equity',
      },
    );
