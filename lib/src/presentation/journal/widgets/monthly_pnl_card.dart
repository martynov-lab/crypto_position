import 'package:crypto_position/src/presentation/journal/monthly_pnl_summary.dart';
import 'package:flutter/material.dart';

/// Summary shown above the journal tab bar: realized PnL for the selected
/// month, totalled across every connected exchange. The month is driven by the
/// tab calendars, so this card only displays it.
class MonthlyPnlCard extends StatelessWidget {
  final MonthlyPnlSummary summary;

  const MonthlyPnlCard({super.key, required this.summary});

  static const _monthNames = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = summary.month;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Прибыль / убыток · ${_monthNames[month.month - 1]} ${month.year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            _buildPnl(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPnl(ThemeData theme) {
    if (summary.loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final pnl = summary.pnl;
    if (pnl == null) {
      return Text(
        '—',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final color = pnl == 0
        ? theme.colorScheme.onSurfaceVariant
        : (pnl > 0 ? Colors.green : Colors.red);
    return Text(
      '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
      style: theme.textTheme.titleMedium?.copyWith(color: color),
    );
  }
}
