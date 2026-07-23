import 'package:crypto_position/src/tab_badge_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final badges = context.read<TabBadgeService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Position')),
      body: navigationShell,
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([badges.mainBadge, badges.screenerBadge]),
        builder: (context, _) => NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _onItemTapped(index, badges),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: badges.mainBadge.value,
                child: const Icon(Icons.home),
              ),
              label: 'Main',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calculate),
              label: 'Calculator',
            ),
            const NavigationDestination(
              icon: Icon(Icons.menu_book),
              label: 'Journal',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: badges.screenerBadge.value,
                child: const Icon(Icons.trending_up),
              ),
              label: 'Screener',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index, TabBadgeService badges) {
    badges.markTabActive(index);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
