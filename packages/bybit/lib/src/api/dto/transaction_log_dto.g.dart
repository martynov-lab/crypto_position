// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_log_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionLogDto _$TransactionLogDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TransactionLogDto', json, ($checkedConvert) {
      final val = TransactionLogDto(
        symbol: $checkedConvert('symbol', (v) => v as String? ?? ''),
        type: $checkedConvert('type', (v) => v as String? ?? ''),
        fee: $checkedConvert('fee', (v) => v as String? ?? ''),
        funding: $checkedConvert('funding', (v) => v as String? ?? ''),
        transactionTime: $checkedConvert(
          'transactionTime',
          (v) => v as String? ?? '',
        ),
      );
      return val;
    });
