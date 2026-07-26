import 'package:crypto_position/src/presentation/screener/coin_chart_screen.dart';
import 'package:crypto_position/src/presentation/screener/screener_screen_wm.dart';
import 'package:crypto_position/src/presentation/screener/widgets/connection_status_badge.dart';
import 'package:crypto_position/src/presentation/screener/widgets/filters_view.dart';
import 'package:crypto_position/src/presentation/screener/widgets/signals_view.dart';
import 'package:crypto_position/src/presentation/screener/widgets/universe_view.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:screener/screener.dart';

/// Arbitrage screener tab: live signals, the traded-instrument universe, and
/// the filters that drive the WS `subscribe`.
class ScreenerScreen extends ElementaryWidget<ScreenerScreenWm> {
  ScreenerScreen({super.key})
      : super((context) => screenerScreenWmFactory(context: context));

  @override
  Widget build(ScreenerScreenWm wm) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          ConnectionStatusBadge(
            connectionState: wm.connectionState,
            error: wm.error,
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Сигналы'),
              Tab(text: 'Вселенная'),
              Tab(text: 'Фильтры'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SignalsView(
                  signals: wm.signals,
                  summary: wm.summary,
                  onRefresh: wm.refreshSummary,
                  configOf: () => wm.clientConfig,
                  onTap: (context, instrument, long, short, entrySpreadPct) =>
                      context.push(
                    '/coin',
                    extra: CoinChartArgs(
                      instrument: instrument,
                      longExchange: long,
                      shortExchange: short,
                      entrySpreadPct: entrySpreadPct,
                    ),
                  ),
                ),
                UniverseView(
                  universe: wm.universe,
                  summary: wm.summary,
                  filters: wm.filters,
                  enabledExchanges: () => wm.enabledExchanges,
                  favorites: wm.favorites,
                  isFavorite: wm.isFavorite,
                  onToggleFavorite: wm.toggleFavorite,
                  onRefresh: wm.refreshSummary,
                  // No pinned pair from the catalog: the chart screen opens on
                  // the first two listed venues it can price, and the pickers
                  // let the user change them.
                  onTap: (context, coverage) => context.push(
                    '/coin',
                    extra: CoinChartArgs(
                      instrument: Instrument(
                        base: coverage.base,
                        quote: coverage.quote,
                        kind: 'perp',
                      ),
                      venues: coverage.exchanges,
                    ),
                  ),
                ),
                FiltersView(
                  initial: wm.clientConfig,
                  onApply: wm.applyConfig,
                  onValidate: wm.validateConfig,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
