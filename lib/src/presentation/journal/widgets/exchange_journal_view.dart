import 'package:crypto_position/src/presentation/journal/exchange_journal.dart';
import 'package:crypto_position/src/presentation/journal/widgets/day_detail_view.dart';
import 'package:crypto_position/src/presentation/journal/widgets/trade_calendar.dart';
import 'package:crypto_position/src/presentation/journal/widgets/trades_table.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One exchange's trade journal: month calendar + closed-trades table, gated on
/// that exchange having credentials. Backed by an [ExchangeJournal].
class ExchangeJournalView extends StatelessWidget {
  final ExchangeJournal journal;
  final ValueListenable<bool> hasCredentials;

  /// Changes the month for the whole screen (every tab and the summary card),
  /// not just this journal, so they stay in sync.
  final ValueChanged<DateTime> onMonthChanged;

  const ExchangeJournalView({
    super.key,
    required this.journal,
    required this.hasCredentials,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: hasCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) {
          return const Center(
            child: Text('Подключите API ключ на вкладке Settings'),
          );
        }
        return _buildJournal(context);
      },
    );
  }

  Widget _buildJournal(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: journal.loading,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return _buildWide(context);
            }
            return _buildNarrow(context);
          },
        );
      },
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: journal.selectedDay,
      builder: (context, selectedDay, _) {
        if (selectedDay != null) {
          return DayDetailView(
            day: selectedDay,
            trades: journal.tradesForDay(selectedDay),
            onBack: () => journal.selectDay(null),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: journal.selectedMonth,
            builder: (context, month, _) {
              return TradeCalendar(
                month: month,
                dailyPnl: journal.dailyPnl,
                dailyTradeCount: journal.dailyTradeCount,
                selectedDay: selectedDay,
                onDayTap: (day) => journal.selectDay(day),
                onMonthChanged: onMonthChanged,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWide(BuildContext context) {
    return ValueListenableBuilder<List<ClosedTradeModel>>(
      valueListenable: journal.trades,
      builder: (context, trades, _) {
        return Column(
          children: [
            ValueListenableBuilder<DateTime>(
              valueListenable: journal.selectedMonth,
              builder: (context, month, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TradeCalendar(
                    month: month,
                    dailyPnl: journal.dailyPnl,
                    dailyTradeCount: journal.dailyTradeCount,
                    selectedDay: null,
                    onDayTap: (_) {},
                    onMonthChanged: onMonthChanged,
                  ),
                );
              },
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TradesTable(trades: trades),
              ),
            ),
          ],
        );
      },
    );
  }
}
