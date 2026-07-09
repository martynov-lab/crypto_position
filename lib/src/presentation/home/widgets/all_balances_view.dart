import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/material.dart';

/// Main-tab view aggregating every connected exchange:
/// 1. total balance + total PnL across all exchanges;
/// 2. per-exchange balance cards (without PnL);
/// 3. open positions grouped by exchange.
///
/// Zero balances and zero PnL values are hidden.
class AllBalancesView extends StatelessWidget {
  final List<ExchangeAccount> accounts;

  const AllBalancesView({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final totalBalance = accounts.fold<double>(
      0,
      (sum, a) => sum + a.totalBalance,
    );
    final totalPnl = accounts.fold<double>(0, (sum, a) => sum + a.totalPnl);

    final balanceCards = accounts.where((a) => a.totalBalance != 0).toList();
    final positionAccounts = accounts
        .where((a) => a.positions.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(context, totalBalance, totalPnl),
        for (final account in balanceCards) ...[
          const SizedBox(height: 8),
          _buildExchangeBalanceCard(context, account),
        ],
        for (final account in positionAccounts) ...[
          const SizedBox(height: 16),
          Text(
            'Позиции · ${account.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...account.positions.map((p) => _buildPositionCard(context, p)),
        ],
      ],
    );
  }

  Widget _buildTotalCard(
    BuildContext context,
    double totalBalance,
    double totalPnl,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общий баланс',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${totalBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (totalPnl != 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${totalPnl >= 0 ? '+' : ''}${totalPnl.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: totalPnl >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeBalanceCard(
    BuildContext context,
    ExchangeAccount account,
  ) {
    return Card(
      child: ListTile(
        title: Text(account.name),
        trailing: Text(
          '\$${account.totalBalance.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context, PositionModel position) {
    final pnl = position.unrealisedPnl;
    return Card(
      child: ListTile(
        title: Text(position.symbol),
        subtitle: Text(
          '${position.side} · ${position.size} @ '
          '${position.avgPrice.toStringAsFixed(2)}',
        ),
        trailing: pnl != 0
            ? Text(
                '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red),
              )
            : null,
      ),
    );
  }
}
