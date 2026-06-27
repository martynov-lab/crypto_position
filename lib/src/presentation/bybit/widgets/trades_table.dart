import 'package:bybit/bybit.dart';
import 'package:flutter/material.dart';

class TradesTable extends StatelessWidget {
  final List<ClosedTrade> trades;

  const TradesTable({super.key, required this.trades});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Нет закрытых сделок за этот период',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest,
        ),
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Контракт')),
          DataColumn(label: Text('Кол-во'), numeric: true),
          DataColumn(label: Text('Цена входа'), numeric: true),
          DataColumn(label: Text('Цена выхода'), numeric: true),
          DataColumn(label: Text('Тип торговли')),
          DataColumn(label: Text('Реализ. P&L'), numeric: true),
          DataColumn(label: Text('Результат')),
          DataColumn(label: Text('Объём открытых'), numeric: true),
          DataColumn(label: Text('Объём закрытых'), numeric: true),
          DataColumn(label: Text('Плечо'), numeric: true),
          DataColumn(label: Text('Время торговли')),
        ],
        rows: trades.map((t) => _buildRow(t, theme)).toList(),
      ),
    );
  }

  DataRow _buildRow(ClosedTrade trade, ThemeData theme) {
    final pnlColor = trade.isProfitable ? Colors.green : Colors.red;
    final dateStr =
        '${trade.createdAt.year}-'
        '${trade.createdAt.month.toString().padLeft(2, '0')}-'
        '${trade.createdAt.day.toString().padLeft(2, '0')} '
        '${trade.createdAt.hour.toString().padLeft(2, '0')}:'
        '${trade.createdAt.minute.toString().padLeft(2, '0')}:'
        '${trade.createdAt.second.toString().padLeft(2, '0')}';

    return DataRow(cells: [
      DataCell(Text(trade.symbol, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(trade.qty.toStringAsFixed(4))),
      DataCell(Text(trade.avgEntryPrice.toStringAsFixed(2))),
      DataCell(Text(trade.avgExitPrice.toStringAsFixed(2))),
      DataCell(Text(trade.tradeType)),
      DataCell(
        Text(
          trade.closedPnl >= 0
              ? '+${trade.closedPnl.toStringAsFixed(4)}'
              : trade.closedPnl.toStringAsFixed(4),
          style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pnlColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            trade.resultLabel,
            style: TextStyle(color: pnlColor, fontSize: 12),
          ),
        ),
      ),
      DataCell(Text(trade.cumEntryValue.toStringAsFixed(2))),
      DataCell(Text(trade.cumExitValue.toStringAsFixed(2))),
      DataCell(Text('${trade.leverage.toStringAsFixed(0)}x')),
      DataCell(Text(dateStr)),
    ]);
  }
}
