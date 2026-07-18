import 'package:crypto_position/src/presentation/journal/journal_screen_wm.dart';
import 'package:crypto_position/src/presentation/journal/monthly_pnl_summary.dart';
import 'package:crypto_position/src/presentation/journal/widgets/exchange_journal_view.dart';
import 'package:crypto_position/src/presentation/journal/widgets/monthly_pnl_card.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class JournalScreen extends ElementaryWidget<JournalScreenWm> {
  JournalScreen({super.key})
    : super((context) => journalScreenWmFactory(context: context));

  @override
  Widget build(JournalScreenWm wm) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          ValueListenableBuilder<MonthlyPnlSummary>(
            valueListenable: wm.monthlyPnl,
            builder: (context, summary, _) => MonthlyPnlCard(summary: summary),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Bybit'),
              Tab(text: 'OKX'),
              Tab(text: 'BitGet'),
              Tab(text: 'Gate'),
              Tab(text: 'MEXC'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExchangeJournalView(
                  journal: wm.bybitJournal,
                  hasCredentials: wm.bybitHasCredentials,
                  onMonthChanged: wm.changeMonth,
                ),
                ExchangeJournalView(
                  journal: wm.okxJournal,
                  hasCredentials: wm.okxHasCredentials,
                  onMonthChanged: wm.changeMonth,
                ),
                ExchangeJournalView(
                  journal: wm.bitgetJournal,
                  hasCredentials: wm.bitgetHasCredentials,
                  onMonthChanged: wm.changeMonth,
                ),
                ExchangeJournalView(
                  journal: wm.gateJournal,
                  hasCredentials: wm.gateHasCredentials,
                  onMonthChanged: wm.changeMonth,
                ),
                ExchangeJournalView(
                  journal: wm.mexcJournal,
                  hasCredentials: wm.mexcHasCredentials,
                  onMonthChanged: wm.changeMonth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
