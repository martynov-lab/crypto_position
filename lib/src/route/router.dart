import 'package:crypto_position/src/components/scaffold_with_nav_bar.dart';
import 'package:crypto_position/src/presentation/home/home_screen.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen.dart';
import 'package:crypto_position/src/presentation/position_calculator/position_calculator.dart';
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
                return PositionCalculator();
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
              path: '/settings',
              builder: (BuildContext context, GoRouterState state) {
                return SettingsScreen();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
