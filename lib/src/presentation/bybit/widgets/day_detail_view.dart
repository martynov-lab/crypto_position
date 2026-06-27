import 'package:bybit/bybit.dart';
import 'package:flutter/material.dart';

class DayDetailView extends StatelessWidget {
  final DateTime day;
  final List<ClosedTrade> trades;
  final VoidCallback onBack;

  const DayDetailView({
    super.key,
    required this.day,
    required this.trades,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPnl = trades.fold<double>(0, (sum, t) => sum + t.closedPnl);
    final wins = trades.where((t) => t.isProfitable).length;
    final dateStr =
        '${day.day.toString().padLeft(2, '0')}.'
        '${day.month.toString().padLeft(2, '0')}.'
        '${day.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Text(dateStr, style: theme.textTheme.titleMedium),
              const SizedBox(width: 12),
              Text(
                '${trades.length} сделок · $wins успешных',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              _buildPnlChip(theme, totalPnl),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: trades.isEmpty
              ? Center(
                  child: Text(
                    'Нет сделок',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: trades.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _buildTradeCard(context, trades[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPnlChip(ThemeData theme, double pnl) {
    final color = pnl >= 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        pnl >= 0
            ? '+\$${pnl.toStringAsFixed(2)}'
            : '-\$${pnl.abs().toStringAsFixed(2)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTradeCard(BuildContext context, ClosedTrade trade) {
    final theme = Theme.of(context);
    final pnlColor = trade.isProfitable ? Colors.green : Colors.red;
    final timeStr =
        '${trade.createdAt.hour.toString().padLeft(2, '0')}:'
        '${trade.createdAt.minute.toString().padLeft(2, '0')}:'
        '${trade.createdAt.second.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  trade.symbol,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pnlColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trade.tradeType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: pnlColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pnlColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trade.resultLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: pnlColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(timeStr, style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  trade.closedPnl >= 0
                      ? '+${trade.closedPnl.toStringAsFixed(4)}'
                      : trade.closedPnl.toStringAsFixed(4),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: pnlColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoColumn('Вход', trade.avgEntryPrice.toStringAsFixed(2)),
                const SizedBox(width: 16),
                _infoColumn('Выход', trade.avgExitPrice.toStringAsFixed(2)),
                const SizedBox(width: 16),
                _infoColumn('Кол-во', trade.qty.toStringAsFixed(4)),
                const SizedBox(width: 16),
                _infoColumn('Плечо', '${trade.leverage.toStringAsFixed(0)}x'),
                const SizedBox(width: 16),
                _infoColumn('Объём откр.', trade.cumEntryValue.toStringAsFixed(2)),
                const SizedBox(width: 16),
                _infoColumn('Объём закр.', trade.cumExitValue.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
