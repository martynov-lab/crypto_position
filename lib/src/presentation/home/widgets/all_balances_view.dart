import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Main-tab view aggregating every connected exchange:
/// 1. total balance + total PnL across all exchanges;
/// 2. per-exchange balance cards (without PnL);
/// 3. open positions grouped by exchange.
///
/// Zero balances and zero PnL values are hidden.
///
/// Long-pressing a position card starts a selection, which the Main screen turns
/// into a bulk exit; a non-empty [selectedKeys] is what selection mode is.
class AllBalancesView extends StatelessWidget {
  final List<ExchangeAccount> accounts;

  /// [positionKey]s of the currently picked positions.
  final Set<String> selectedKeys;

  /// Called with a position's [positionKey] on long press, and on tap while a
  /// selection is active.
  final ValueChanged<String>? onToggleSelection;

  const AllBalancesView({
    super.key,
    required this.accounts,
    this.selectedKeys = const {},
    this.onToggleSelection,
  });

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
      // Keeps pull-to-refresh reachable when the content fits the viewport.
      physics: const AlwaysScrollableScrollPhysics(),
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
          ...account.positions.map(
            (p) => _buildPositionCard(context, account.exchange, p),
          ),
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

  Widget _buildPositionCard(
    BuildContext context,
    ExchangeId exchange,
    PositionModel position,
  ) {
    final theme = Theme.of(context);
    final pnl = position.unrealisedPnl;
    final key = positionKey(exchange, position);
    final selected = selectedKeys.contains(key);
    final selecting = selectedKeys.isNotEmpty;

    return Card(
      // A selected card is outlined rather than tinted, so the PnL colours stay
      // readable.
      shape: selected
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: onToggleSelection == null
            ? null
            : () => onToggleSelection!(key),
        // Outside selection mode a tap does nothing, so it can't start an exit
        // by accident.
        onTap: (selecting && onToggleSelection != null)
            ? () => onToggleSelection!(key)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selecting) ...[
                    Icon(
                      selected
                          ? AppIcons.check_circle_filled_24
                          : AppIcons.check_circle_outlined_24,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.symbol,
                          style: theme.textTheme.titleMedium,
                        ),
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
