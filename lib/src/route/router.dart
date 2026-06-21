import 'package:crypto_position/src/components/scaffold_with_nav_bar.dart';
import 'package:crypto_position/src/home_screen.dart';
import 'package:crypto_position/src/position_calculator/position_calculator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

GoRouter get router => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/calculator',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    /// Application shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: <RouteBase>[
        /// The first screen to display in the bottom navigation bar.
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
          routes: <RouteBase>[
            // The details screen to display stacked on the inner Navigator.
            // This will cover screen A but not the application shell.
            // GoRoute(
            //   path: 'details',
            //   builder: (BuildContext context, GoRouterState state) {
            //     return const DetailsScreen(label: 'A');
            //   },
            // ),
          ],
        ),

        /// Displayed when the second item in the the bottom navigation bar is
        /// selected.
        GoRoute(
          path: '/calculator',
          builder: (BuildContext context, GoRouterState state) {
            return PositionCalculator();
          },
          // routes: <RouteBase>[
          //   /// Same as "/a/details", but displayed on the root Navigator by
          //   /// specifying [parentNavigatorKey]. This will cover both screen B
          //   /// and the application shell.
          //   GoRoute(
          //     path: 'details',
          //     parentNavigatorKey: _rootNavigatorKey,
          //     builder: (BuildContext context, GoRouterState state) {
          //       return const DetailsScreen(label: 'B');
          //     },
          //   ),
          // ],
        ),

        /// The third screen to display in the bottom navigation bar.
        // GoRoute(
        //   path: '/c',
        //   builder: (BuildContext context, GoRouterState state) {
        //     return const ScreenC();
        //   },
        //   routes: <RouteBase>[
        //     // The details screen to display stacked on the inner Navigator.
        //     // This will cover screen C but not the application shell.
        //     GoRoute(
        //       path: 'details',
        //       builder: (BuildContext context, GoRouterState state) {
        //         return const DetailsScreen(label: 'C');
        //       },
        //     ),
        //   ],
        // ),
      ],
    ),
  ],
);
