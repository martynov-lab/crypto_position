import 'package:json_annotation/json_annotation.dart';

part 'contract_dto.g.dart';

/// Public `/futures/{settle}/contracts` entry.
///
/// Only the funding schedule is parsed: Gate's ticker carries the rate but not
/// the settlement time, so [fundingNextApply] fills that gap.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class ContractDto {
  @JsonKey(defaultValue: '')
  final String name;

  /// Epoch **seconds** of the next settlement — Gate times these in seconds,
  /// unlike the millisecond timestamps every other exchange here uses.
  @JsonKey(defaultValue: 0)
  final num fundingNextApply;

  const ContractDto({required this.name, required this.fundingNextApply});

  factory ContractDto.fromJson(Map<String, Object?> json) =>
      _$ContractDtoFromJson(json);
}
