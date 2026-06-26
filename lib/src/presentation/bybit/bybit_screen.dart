import 'package:bybit_api/bybit_api.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen_wm.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class BybitScreen extends ElementaryWidget<BybitScreenWm> {
  BybitScreen({super.key})
    : super((context) => bybitScreenWmFactory(context: context));

  @override
  Widget build(BybitScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.hasCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) return _buildLoginForm(context, wm);
        return _buildBalanceView(context, wm);
      },
    );
  }

  Widget _buildLoginForm(BuildContext context, BybitScreenWm wm) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.key,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Подключение к Bybit',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: wm.apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wm.apiSecretController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Secret',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: wm.saveCredentials,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceView(BuildContext context, BybitScreenWm wm) {
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
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: wm.logout,
                        child: const Text('Сбросить ключ'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<WalletBalance?>(
              valueListenable: wm.balance,
              builder: (context, wallet, _) {
                if (wallet == null) {
                  return const Center(child: Text('Нет данных'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Общий баланс',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${wallet.totalWalletBalance.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...wallet.coins.map((coin) => Card(
                      child: ListTile(
                        title: Text(coin.coin),
                        subtitle: Text(
                          'Баланс: ${coin.walletBalance.toStringAsFixed(4)}',
                        ),
                        trailing: Text(
                          'PnL: ${coin.unrealisedPnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: coin.unrealisedPnl >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: wm.logout,
                      child: const Text('Отключить API'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
