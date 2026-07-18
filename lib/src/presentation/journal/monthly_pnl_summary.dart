/// Realized PnL for one calendar month, summed across every connected
/// exchange's closed trades. Drives the summary card above the journal tabs.
class MonthlyPnlSummary {
  /// The month this summary is for (day is always the 1st).
  final DateTime month;

  /// Total realized PnL for [month]; null when no exchange is connected (or the
  /// value is not yet known), which renders as a dash rather than a false zero.
  final double? pnl;

  /// Whether a fetch for [month] is in flight.
  final bool loading;

  const MonthlyPnlSummary({
    required this.month,
    this.pnl,
    this.loading = false,
  });
}
