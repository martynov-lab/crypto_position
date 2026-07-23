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

  /// Converts a wire fraction decimal-string (e.g. `"0.006"`) to a plain
  /// percent number-string for an editable field (e.g. `"0.6"`). Multiplying
  /// by the exact `Decimal` 100 keeps this precision-safe, unlike `double`
  /// math. `null`/unparsable input passes through as `null`.
  static String? toPercentInput(String? raw) {
    final value = parse(raw);
    if (value == null) return null;
    return (value * Decimal.fromInt(100)).toString();
  }

  /// Inverse of [toPercentInput]: a percent number typed by the user (e.g.
  /// `"0.6"`) back to the fraction decimal-string the wire expects
  /// (`"0.006"`). Unparsable input is passed through unchanged so the
  /// server's own validation (not a silent client-side guess) reports it.
  static String? fromPercentInput(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = Decimal.tryParse(trimmed);
    if (value == null) return trimmed;
    return (value * Decimal.parse('0.01')).toString();
  }

  /// Formats a price/notional decimal-string for display, rounded to at most
  /// [maxFractionDigits] decimal places (default 5) with trailing zeros
  /// trimmed — display-only, never used for the value actually sent on the
  /// wire. Returns the raw string if it is not a valid decimal.
  static String amount(String raw, {int maxFractionDigits = 5}) {
    final value = Decimal.tryParse(raw);
    if (value == null) return raw;
    var fixed = value.toStringAsFixed(maxFractionDigits);
    if (fixed.contains('.')) {
      fixed = fixed.replaceFirst(RegExp(r'0+$'), '');
      fixed = fixed.replaceFirst(RegExp(r'\.$'), '');
    }
    return fixed;
  }
}
