import 'package:json_annotation/json_annotation.dart';

part 'contract_detail_dto.g.dart';

/// One contract from public REST `/contract/detail`. [contractSize] is the
/// multiplier converting a position's contract count (`holdVol`) into the base
/// asset quantity.
@JsonSerializable(checked: true, createToJson: false)
class ContractDetailDto {
  @JsonKey(defaultValue: '')
  final String symbol;
  @JsonKey(defaultValue: 0)
  final num contractSize;

  const ContractDetailDto({required this.symbol, required this.contractSize});

  factory ContractDetailDto.fromJson(Map<String, Object?> json) =>
      _$ContractDetailDtoFromJson(json);
}
