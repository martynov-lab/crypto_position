import 'package:json_annotation/json_annotation.dart';

part 'transaction_log_dto.g.dart';

/// One entry of REST `/v5/account/transaction-log`.
///
/// Only two [type]s matter here: `TRADE` carries the trading [fee], and
/// `SETTLEMENT` carries the [funding] cash flow. Both are signed from the
/// account's point of view, but with opposite conventions:
/// [fee] is positive when charged (negative is a rebate), while [funding] is
/// positive when received and negative when paid.
@JsonSerializable(checked: true, createToJson: false)
class TransactionLogDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: '')
  final String type;
  @JsonKey(defaultValue: '')
  final String fee;
  @JsonKey(defaultValue: '')
  final String funding;

  /// Epoch milliseconds, as a string.
  @JsonKey(defaultValue: '')
  final String transactionTime;

  const TransactionLogDto({
    required this.symbol,
    required this.type,
    required this.fee,
    required this.funding,
    required this.transactionTime,
  });

  factory TransactionLogDto.fromJson(Map<String, Object?> json) =>
      _$TransactionLogDtoFromJson(json);
}
