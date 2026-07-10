import 'package:crypto_position/src/presentation/journal/journal_screen_wm.dart';
import 'package:crypto_position/src/presentation/journal/widgets/exchange_journal_view.dart';
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
                ),
                ExchangeJournalView(
                  journal: wm.okxJournal,
                  hasCredentials: wm.okxHasCredentials,
                ),
                ExchangeJournalView(
                  journal: wm.bitgetJournal,
                  hasCredentials: wm.bitgetHasCredentials,
                ),
                ExchangeJournalView(
                  journal: wm.gateJournal,
                  hasCredentials: wm.gateHasCredentials,
                ),
                ExchangeJournalView(
                  journal: wm.mexcJournal,
                  hasCredentials: wm.mexcHasCredentials,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
