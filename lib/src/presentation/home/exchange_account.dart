import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:exchange/exchange.dart';

/// A snapshot of one connected exchange for the Main tab: its balance and
/// current open positions.
class ExchangeAccount {
  /// Which exchange this is, used to resolve its trade executor and market data
  /// when closing a position.
  final ExchangeId exchange;

  final String name;
  final BalanceModel balance;
  final List<PositionModel> positions;

  const ExchangeAccount({
    required this.exchange,
    required this.name,
    required this.balance,
    required this.positions,
  });

  double get totalBalance => balance.totalWalletBalance;

  double get totalPnl =>
      positions.fold(0, (sum, position) => sum + position.unrealisedPnl);
}

/// Stable identity of one open position across rebuilds, used to keep a
/// selection alive while balances and PnL tick. Side is part of the key because
/// a hedge-mode account can hold both directions of the same symbol at once.
String positionKey(ExchangeId exchange, PositionModel position) =>
    '${exchange.key}|${position.symbol}|${position.side}';
