import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:crypto_position/src/presentation/home/home_screen_wm.dart';
import 'package:crypto_position/src/presentation/widgets/balance_view.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class HomeScreen extends ElementaryWidget<HomeScreenWm> {
  HomeScreen({super.key})
    : super((context) => homeScreenWmFactory(context: context));

  @override
  Widget build(HomeScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.hasCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) {
          return const Center(
            child: Text('Подключите API ключ на вкладке Bybit'),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: wm.loading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<String?>(
              valueListenable: wm.error,
              builder: (context, err, _) {
                if (err != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(err, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ValueListenableBuilder<BybitAccountSession?>(
                  valueListenable: wm.session,
                  builder: (context, session, _) {
                    if (session == null) {
                      return const Center(child: Text('Нет данных'));
                    }
                    return ValueListenableBuilder<WalletBalanceModel?>(
                      valueListenable: session.repository.balance,
                      builder: (context, wallet, _) {
                        if (wallet == null) {
                          return const Center(child: Text('Нет данных'));
                        }
                        return ValueListenableBuilder<List<PositionModel>?>(
                          valueListenable: session.repository.positions,
                          builder: (context, positions, _) {
                            return BalanceView(
                              wallet: wallet,
                              positions: positions ?? const [],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
