// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GateAccountDto _$GateAccountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GateAccountDto',
      json,
      ($checkedConvert) {
        final val = GateAccountDto(
          user: $checkedConvert('user', (v) => (v as num?)?.toInt() ?? 0),
          currency: $checkedConvert('currency', (v) => v as String? ?? 'USDT'),
          total: $checkedConvert('total', (v) => v as String? ?? '0'),
          available: $checkedConvert('available', (v) => v as String? ?? '0'),
          unrealisedPnl: $checkedConvert(
            'unrealised_pnl',
            (v) => v as String? ?? '0',
          ),
          crossMarginBalance: $checkedConvert(
            'cross_margin_balance',
            (v) => v as String? ?? '0',
          ),
          crossAvailable: $checkedConvert(
            'cross_available',
            (v) => v as String? ?? '0',
          ),
          crossInitialMargin: $checkedConvert(
            'cross_initial_margin',
            (v) => v as String? ?? '0',
          ),
          crossOrderMargin: $checkedConvert(
            'cross_order_margin',
            (v) => v as String? ?? '0',
          ),
          crossUnrealisedPnl: $checkedConvert(
            'cross_unrealised_pnl',
            (v) => v as String? ?? '0',
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'unrealisedPnl': 'unrealised_pnl',
        'crossMarginBalance': 'cross_margin_balance',
        'crossAvailable': 'cross_available',
        'crossInitialMargin': 'cross_initial_margin',
        'crossOrderMargin': 'cross_order_margin',
        'crossUnrealisedPnl': 'cross_unrealised_pnl',
      },
    );
