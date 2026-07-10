import 'package:exchange/exchange.dart';

import '../dto/balance_dto.dart';
import '../dto/unified_account_dto.dart';

extension GateBalanceMapper on GateAccountDto {
  BalanceModel toModel() {
    // Gate futures totals are already in USDT. There is no separate wallet
    // total, so account equity is the closest equivalent for both.
    final equity = _equity();
    final wallet = _coalesce(available, crossAvailable);
    final upl = _coalesce(unrealisedPnl, crossUnrealisedPnl);
    return BalanceModel(
      totalEquity: equity,
      totalWalletBalance: equity,
      coins: [
        CoinBalanceModel(
          coin: currency,
          equity: equity,
          walletBalance: wallet,
          usdValue: equity,
          unrealisedPnl: upl,
        ),
      ],
    );
  }

  /// Isolated accounts report equity in [total]. Classic cross-margin accounts
  /// leave it at 0 and expose the parts under `cross_*`; `cross_margin_balance`
  /// is often absent, so rebuild it as free + locked margin + unrealised PnL.
  double _equity() {
    final totalRaw = _parseAmount(total);
    if (totalRaw != 0) return totalRaw;

    final crossBalance = _parseAmount(crossMarginBalance);
    if (crossBalance != 0) return crossBalance;

    return _parseAmount(crossAvailable) +
        _parseAmount(crossInitialMargin) +
        _parseAmount(crossOrderMargin) +
        _parseAmount(crossUnrealisedPnl);
  }
}

extension UnifiedBalanceMapper on UnifiedAccountDto {
  BalanceModel toModel() {
    // Equity (wallet + unrealised) is the closest exchange-agnostic total; fall
    // back to the plain USD asset total when equity is not reported.
    final equity = _coalesce(unifiedAccountTotalEquity, total);
    return BalanceModel(
      totalEquity: equity,
      totalWalletBalance: equity,
      coins: [
        CoinBalanceModel(
          coin: 'USDT',
          equity: equity,
          walletBalance: equity,
          usdValue: equity,
          unrealisedPnl: 0,
        ),
      ],
    );
  }
}

/// Uses [primary] unless it parses to 0, then the [fallback] field.
double _coalesce(String primary, String fallback) {
  final value = _parseAmount(primary);
  return value != 0 ? value : _parseAmount(fallback);
}

/// Gate returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
