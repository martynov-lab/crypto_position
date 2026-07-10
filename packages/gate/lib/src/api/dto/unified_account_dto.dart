import 'package:json_annotation/json_annotation.dart';

part 'unified_account_dto.g.dart';

/// The unified account from REST `/unified/accounts`. Used as a fallback when
/// the classic futures account is empty because the user is on a unified
/// account (funds live in one shared wallet).
///
/// [total] is total assets converted to USD; [unifiedAccountTotalEquity] is the
/// account equity (valid in the unified margin modes).
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class UnifiedAccountDto {
  @JsonKey(defaultValue: 0)
  final int userId;
  @JsonKey(defaultValue: '0')
  final String total;
  @JsonKey(defaultValue: '0')
  final String unifiedAccountTotalEquity;

  const UnifiedAccountDto({
    required this.userId,
    required this.total,
    required this.unifiedAccountTotalEquity,
  });

  factory UnifiedAccountDto.fromJson(Map<String, Object?> json) =>
      _$UnifiedAccountDtoFromJson(json);
}
