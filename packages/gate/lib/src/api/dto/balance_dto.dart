import 'package:json_annotation/json_annotation.dart';

part 'balance_dto.g.dart';

/// The single futures account object from REST `/futures/usdt/accounts`.
///
/// Only [user], the numeric account id, is parsed: it is what private
/// WebSocket subscriptions need. The account's balance fields are deliberately
/// ignored — they cover the futures wallet alone, while the displayed balance
/// comes from `/wallet/total_balance`, which sums every wallet.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class GateAccountDto {
  @JsonKey(defaultValue: 0)
  final int user;

  const GateAccountDto({required this.user});

  factory GateAccountDto.fromJson(Map<String, Object?> json) =>
      _$GateAccountDtoFromJson(json);
}
