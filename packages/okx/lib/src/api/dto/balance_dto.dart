import 'package:json_annotation/json_annotation.dart';

part 'balance_dto.g.dart';

/// One element of the `data` array from REST `/api/v5/account/balance`
/// or the private `account` WebSocket channel.
@JsonSerializable(checked: true, createToJson: false)
class BalanceDto {
  @JsonKey(defaultValue: '0')
  final String totalEq;
  @JsonKey(defaultValue: [])
  final List<CoinBalanceDto> details;

  const BalanceDto({required this.totalEq, required this.details});

  factory BalanceDto.fromJson(Map<String, Object?> json) =>
      _$BalanceDtoFromJson(json);
}

@JsonSerializable(checked: true, createToJson: false)
class CoinBalanceDto {
  @JsonKey(defaultValue: '')
  final String ccy;
  @JsonKey(defaultValue: '0')
  final String eq;
  @JsonKey(defaultValue: '0')
  final String cashBal;
  @JsonKey(defaultValue: '0')
  final String eqUsd;
  @JsonKey(defaultValue: '0')
  final String upl;

  const CoinBalanceDto({
    required this.ccy,
    required this.eq,
    required this.cashBal,
    required this.eqUsd,
    required this.upl,
  });

  factory CoinBalanceDto.fromJson(Map<String, Object?> json) =>
      _$CoinBalanceDtoFromJson(json);
}
