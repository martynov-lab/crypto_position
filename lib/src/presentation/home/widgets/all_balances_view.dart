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
    final theme = Theme.of(context);
    final pnl = position.unrealisedPnl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position.symbol, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${position.side} · ${position.size} @ '
                        '${position.avgPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pnl != 0)
                  Text(
                    '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: pnl >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailRow(
              context,
              _nextFundingLabel(position.nextFundingTime),
              position.upcomingFundingUsd,
            ),
          ],
        ),
      ),
    );
  }

  /// One `label — amount` line. A null [amount] means the exchange does not
  /// report the value, and shows a dash rather than a misleading zero.
  Widget _buildDetailRow(BuildContext context, String label, double? amount) {
    final theme = Theme.of(context);
    final Color color;
    if (amount == null || amount == 0) {
      color = theme.colorScheme.onSurfaceVariant;
    } else {
      color = amount > 0 ? Colors.green : Colors.red;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          amount == null
              ? '—'
              : '${amount > 0 ? '+' : ''}${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  String _nextFundingLabel(DateTime? nextFundingTime) {
    if (nextFundingTime == null) return 'Следующий фандинг';

    final hh = nextFundingTime.hour.toString().padLeft(2, '0');
    final mm = nextFundingTime.minute.toString().padLeft(2, '0');
    return 'Следующий фандинг · $hh:$mm';
  }
}
