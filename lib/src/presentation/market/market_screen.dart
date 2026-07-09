import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/presentation/market/market_screen_wm.dart';
import 'package:crypto_position/src/presentation/market/widgets/day_detail_view.dart';
import 'package:crypto_position/src/presentation/market/widgets/settings_view.dart';
import 'package:crypto_position/src/presentation/market/widgets/trade_calendar.dart';
import 'package:crypto_position/src/presentation/market/widgets/trades_table.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class MarketScreen extends ElementaryWidget<MarketScreenWm> {
  MarketScreen({super.key})
    : super((context) => marketScreenWmFactory(context: context));

  @override
  Widget build(MarketScreenWm wm) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Журнал', icon: Icon(Icons.menu_book)),
              Tab(text: 'Настройки', icon: Icon(Icons.settings)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildJournalTabGuarded(wm), _buildSettingsTab(wm)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(MarketScreenWm wm) {
    return ListenableBuilder(
      listenable: wm.connectionsListenable,
      builder: (context, _) => SettingsView(connections: wm.connections),
    );
  }

  Widget _buildJournalTabGuarded(MarketScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.hasCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) {
          return const Center(
            child: Text('Подключите API ключ на вкладке Настройки'),
          );
        }
        return _buildJournalTab(context, wm);
      },
    );
  }

  Widget _buildJournalTab(BuildContext context, MarketScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.tradesLoading,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return _buildWideJournal(context, wm);
            }
            return _buildNarrowJournal(context, wm);
          },
        );
      },
    );
  }

  Widget _buildNarrowJournal(BuildContext context, MarketScreenWm wm) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: wm.selectedDay,
      builder: (context, selectedDay, _) {
        if (selectedDay != null) {
          return DayDetailView(
            day: selectedDay,
            trades: wm.tradesForDay(selectedDay),
            onBack: () => wm.selectDay(null),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: wm.selectedMonth,
            builder: (context, month, _) {
              return TradeCalendar(
                month: month,
                dailyPnl: wm.dailyPnl,
                dailyTradeCount: wm.dailyTradeCount,
                selectedDay: selectedDay,
                onDayTap: (day) => wm.selectDay(day),
                onMonthChanged: wm.changeMonth,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWideJournal(BuildContext context, MarketScreenWm wm) {
    return ValueListenableBuilder<List<ClosedTradeModel>>(
      valueListenable: wm.trades,
      builder: (context, trades, _) {
        return Column(
          children: [
            ValueListenableBuilder<DateTime>(
              valueListenable: wm.selectedMonth,
              builder: (context, month, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TradeCalendar(
                    month: month,
                    dailyPnl: wm.dailyPnl,
                    dailyTradeCount: wm.dailyTradeCount,
                    selectedDay: null,
                    onDayTap: (_) {},
                    onMonthChanged: wm.changeMonth,
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
