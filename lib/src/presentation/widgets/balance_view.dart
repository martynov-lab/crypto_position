import 'package:bybit/bybit.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class BalanceView extends StatelessWidget {
  final WalletBalanceModel wallet;
  final VoidCallback? onLogout;

  const BalanceView({super.key, required this.wallet, this.onLogout});

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...wallet.coins.map(
          (coin) => Card(
            child: ListTile(
              title: Text(coin.coin),
              subtitle: Text(
                'Баланс: ${coin.walletBalance.toStringAsFixed(4)}',
              ),
              trailing: Text(
                'PnL: ${coin.unrealisedPnl.toStringAsFixed(2)}',
                style: TextStyle(
                  color: coin.unrealisedPnl >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ),
        if (onLogout != null) ...[
          const SizedBox(height: 16),
          AppButton.outlined(onPressed: onLogout, label: 'Отключить API'),
        ],
      ],
    );
  }
}
