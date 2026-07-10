// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_close_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionCloseDto _$PositionCloseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PositionCloseDto',
      json,
      ($checkedConvert) {
        final val = PositionCloseDto(
          time: $checkedConvert('time', (v) => v as num? ?? 0),
          contract: $checkedConvert('contract', (v) => v as String? ?? ''),
          side: $checkedConvert('side', (v) => v as String? ?? ''),
          pnl: $checkedConvert('pnl', (v) => v as String? ?? '0'),
          accumSize: $checkedConvert('accum_size', (v) => v as String? ?? '0'),
          longPrice: $checkedConvert('long_price', (v) => v as String? ?? '0'),
          shortPrice: $checkedConvert(
            'short_price',
            (v) => v as String? ?? '0',
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'accumSize': 'accum_size',
        'longPrice': 'long_price',
        'shortPrice': 'short_price',
      },
    );
