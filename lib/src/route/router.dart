import 'package:crypto_position/src/components/scaffold_with_nav_bar.dart';
import 'package:crypto_position/src/presentation/home/home_screen.dart';
import 'package:crypto_position/src/presentation/calculator/calculator_screen.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen.dart';
import 'package:crypto_position/src/presentation/screener/coin_chart_screen.dart';
import 'package:crypto_position/src/presentation/screener/screener_screen.dart';
import 'package:crypto_position/src/presentation/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter get router => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) {
                return HomeScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calculator',
              builder: (BuildContext context, GoRouterState state) {
                return const CalculatorScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (BuildContext context, GoRouterState state) {
                return JournalScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/screener',
              builder: (BuildContext context, GoRouterState state) {
                return ScreenerScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (BuildContext context, GoRouterState state) {
                return SettingsScreen();
              },
            ),
          ],
        ),
      ],
    ),
    // Pushed over the bottom-nav shell (root navigator) so the chart is
    // full-screen with its own back button.
    GoRoute(
      path: '/coin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        return CoinChartScreen(args: state.extra! as CoinChartArgs);
      },
    ),
  ],
);
