import 'package:decimal/decimal.dart';

/// Helpers for the wire format's decimal-as-string convention.
///
/// Every monetary/ratio field arrives as a JSON string to avoid float
/// precision loss (see the integration guide, §0). We keep the raw string for
/// display and parse to [Decimal] — never `double` — for comparisons.
class Decimals {
  const Decimals._();

  /// Coerces a JSON value to its string form. Tolerates a server that sends a
  /// bare number for a field the guide documents as a string.
  static String str(Object? value) => value?.toString() ?? '';

  /// Parses a decimal-string to [Decimal], or `null` when absent/malformed.
  static Decimal? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return Decimal.tryParse(raw);
  }

  /// Whether [raw] parses to a value below zero.
  static bool isNegative(String? raw) {
    final value = parse(raw);
    return value != null && value < Decimal.zero;
  }

  /// Formats a fraction string (e.g. `"0.0289"`) as a percent label
  /// (`"2.89%"`). Returns the raw string if it is not a valid decimal.
  static String percent(String raw, {int fractionDigits = 2}) {
    final value = Decimal.tryParse(raw);
    if (value == null) return raw;
    final scaled = value * Decimal.fromInt(100);
    return '${scaled.toStringAsFixed(fractionDigits)}%';
  }
}
