// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionDto _$PositionDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PositionDto',
  json,
  ($checkedConvert) {
    final val = PositionDto(
      contract: $checkedConvert('contract', (v) => v as String? ?? ''),
      size: $checkedConvert('size', (v) => (v as num?)?.toInt() ?? 0),
      leverage: $checkedConvert('leverage', (v) => v as String? ?? '0'),
      entryPrice: $checkedConvert('entry_price', (v) => v as String? ?? '0'),
      markPrice: $checkedConvert('mark_price', (v) => v as String? ?? '0'),
      unrealisedPnl: $checkedConvert(
        'unrealised_pnl',
        (v) => v as String? ?? '0',
      ),
      value: $checkedConvert('value', (v) => v as String? ?? '0'),
    );
    return val;
  },
  fieldKeyMap: const {
    'entryPrice': 'entry_price',
    'markPrice': 'mark_price',
    'unrealisedPnl': 'unrealised_pnl',
  },
);
