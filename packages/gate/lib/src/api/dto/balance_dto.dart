import 'package:json_annotation/json_annotation.dart';

part 'balance_dto.g.dart';

/// The single futures account object from REST `/futures/usdt/accounts`.
/// [user] is the numeric account id, needed for private WebSocket subscriptions.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class GateAccountDto {
  @JsonKey(defaultValue: 0)
  final int user;
  @JsonKey(defaultValue: 'USDT')
  final String currency;
  @JsonKey(defaultValue: '0')
  final String total;
  @JsonKey(defaultValue: '0')
  final String available;
  @JsonKey(defaultValue: '0')
  final String unrealisedPnl;

  // Classic cross-margin / unified accounts report equity under these `cross_*`
  // fields and can leave the isolated [total]/[available] at "0".
  @JsonKey(defaultValue: '0')
  final String crossMarginBalance;
  @JsonKey(defaultValue: '0')
  final String crossAvailable;
  @JsonKey(defaultValue: '0')
  final String crossUnrealisedPnl;

  const GateAccountDto({
    required this.user,
    required this.currency,
    required this.total,
    required this.available,
    required this.unrealisedPnl,
    required this.crossMarginBalance,
    required this.crossAvailable,
    required this.crossUnrealisedPnl,
  });

  factory GateAccountDto.fromJson(Map<String, Object?> json) =>
      _$GateAccountDtoFromJson(json);
}
