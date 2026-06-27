import 'package:flutter/material.dart';

class TradeCalendar extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, double> dailyPnl;
  final Map<DateTime, int> dailyTradeCount;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onMonthChanged;

  const TradeCalendar({
    super.key,
    required this.month,
    required this.dailyPnl,
    required this.dailyTradeCount,
    required this.selectedDay,
    required this.onDayTap,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday;

    return Column(
      children: [
        _buildMonthHeader(context, theme),
        const SizedBox(height: 8),
        _buildWeekdayLabels(theme),
        const SizedBox(height: 4),
        _buildDayGrid(context, theme, daysInMonth, startWeekday),
      ],
    );
  }

  Widget _buildMonthHeader(BuildContext context, ThemeData theme) {
    const months = [
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () =>
              onMonthChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${months[month.month - 1]} ${month.year}',
          style: theme.textTheme.titleMedium,
        ),
        IconButton(
          onPressed: () =>
              onMonthChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(ThemeData theme) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid(
    BuildContext context,
    ThemeData theme,
    int daysInMonth,
    int startWeekday,
  ) {
    final cells = <Widget>[];

    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final pnl = dailyPnl[date];
      final count = dailyTradeCount[date] ?? 0;
      final isSelected =
          selectedDay != null &&
          selectedDay!.year == date.year &&
          selectedDay!.month == date.month &&
          selectedDay!.day == date.day;
      final isToday = date == today;

      cells.add(_buildDayCell(context, theme, day, date, pnl, count, isSelected, isToday));
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final end = (i + 7 > cells.length) ? cells.length : i + 7;
      final rowCells = cells.sublist(i, end);
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox());
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: rowCells.map((c) => Expanded(child: c)).toList(),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(
    BuildContext context,
    ThemeData theme,
    int day,
    DateTime date,
    double? pnl,
    int tradeCount,
    bool isSelected,
    bool isToday,
  ) {
    Color? bgColor;
    if (pnl != null) {
      bgColor = pnl >= 0
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.red.withValues(alpha: 0.3);
    }

    Border? border;
    if (isSelected) {
      border = Border.all(color: theme.colorScheme.primary, width: 2);
    } else if (isToday) {
      border = Border.all(color: theme.colorScheme.outline, width: 1.5);
    }

    return GestureDetector(
      onTap: () => onDayTap(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        alignment: Alignment.center,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: (isSelected || isToday) ? FontWeight.bold : null,
              ),
            ),
            if (pnl != null)
              Text(
                '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(1)} ($tradeCount)',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: pnl >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
