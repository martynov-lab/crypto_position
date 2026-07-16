import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_model.freezed.dart';

/// How far back fee and funding history is queried.
///
/// Exchanges page these logs in short windows (Bybit: 7 days, 50 entries), so
/// an uncapped lookback on a long-held position costs enough requests to risk
/// a rate-limit ban. Totals for a position older than this are partial, which
/// [PositionModel.hasPartialFees] reports so the UI can say so.
const feesLookbackWindow = Duration(days: 30);

/// Exchange-agnostic open position.
///
/// [side] keeps each exchange's own wording (e.g. Bybit `Buy`/`Sell`, OKX
/// `long`/`short`); PnL is computed inside each exchange's repository.
///
/// The funding and fee fields are nullable on purpose: not every exchange
/// reports them, so `null` means "unknown" and renders as a dash, which a `0`
/// would silently misreport as "nothing was paid".
@freezed
abstract class PositionModel with _$PositionModel {
  const PositionModel._();

  const factory PositionModel({
    required String symbol,
    required String side,
    required double size,
    required double avgPrice,
    required double markPrice,
    required double unrealisedPnl,
    required double leverage,

    /// When the position was opened; anchors the fee/funding window.
    DateTime? createdAt,

    /// Funding rate for the upcoming settlement, as a fraction (0.0001 = 0.01%).
    double? fundingRate,
    DateTime? nextFundingTime,

    /// Funding due at [nextFundingTime], signed from the account's point of
    /// view: negative is paid out, positive is received. Computed inside each
    /// exchange's repository, which knows how [side] is worded.
    double? upcomingFundingUsd,

    /// Trading fees paid over this position's life, as a positive number.
    double? paidCommission,

    /// Funding settled over this position's life, signed like
    /// [upcomingFundingUsd]: negative is paid out, positive is received.
    double? paidFunding,

    /// Start of the window [paidCommission] and [paidFunding] cover. Equals
    /// [createdAt] for a position opened within [feesLookbackWindow]; for an
    /// older one it is capped to that window, making the totals partial.
    DateTime? feesSince,
  }) = _PositionModel;

  /// Position value at the mark price, in the quote currency.
  double get notional => size.abs() * markPrice;

  /// Whether the fee totals cover less than the position's whole life, because
  /// [feesLookbackWindow] cut the query short.
  bool get hasPartialFees {
    final since = feesSince;
    final opened = createdAt;
    if (since == null || opened == null) return false;
    return since.isAfter(opened);
  }
}
