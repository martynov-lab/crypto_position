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
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Bybit'),
              Tab(text: 'OKX'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
