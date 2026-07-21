import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/home_screen_wm.dart';
import 'package:crypto_position/src/presentation/home/widgets/all_balances_view.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class HomeScreen extends ElementaryWidget<HomeScreenWm> {
  HomeScreen({super.key})
    : super((context) => homeScreenWmFactory(context: context));

  @override
  Widget build(HomeScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.hasAnyCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) {
          return const Center(
            child: Text('Подключите API ключ на вкладке Settings'),
          );
        }

        return ValueListenableBuilder<List<ExchangeAccount>>(
          valueListenable: wm.accounts,
          builder: (context, accounts, _) {
            if (accounts.isEmpty) {
              return ValueListenableBuilder<bool>(
                valueListenable: wm.loading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(child: Text('Нет данных'));
                },
              );
            }
            return RefreshIndicator(
              onRefresh: wm.refresh,
              child: AllBalancesView(accounts: accounts),
            );
          },
        );
      },
    );
  }
}
