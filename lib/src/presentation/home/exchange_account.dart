import 'package:exchange/exchange.dart';

/// A snapshot of one connected exchange for the Main tab: its balance and
/// current open positions.
class ExchangeAccount {
  final String name;
  final BalanceModel balance;
  final List<PositionModel> positions;

  const ExchangeAccount({
    required this.name,
    required this.balance,
    required this.positions,
  });

  double get totalBalance => balance.totalWalletBalance;

  double get totalPnl =>
      positions.fold(0, (sum, position) => sum + position.unrealisedPnl);
}
