import 'package:bybit/bybit.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class BalanceView extends StatelessWidget {
  final WalletBalanceModel wallet;
  final List<PositionModel> positions;
  final VoidCallback? onLogout;

  const BalanceView({
    super.key,
    required this.wallet,
    this.positions = const [],
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final totalPnl = positions.fold<double>(
      0,
      (sum, position) => sum + position.unrealisedPnl,
    );

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$${wallet.totalWalletBalance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    if (positions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${totalPnl >= 0 ? '+' : ''}${totalPnl.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: totalPnl >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (positions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...positions.map(
            (position) => Card(
              child: ListTile(
                title: Text(position.symbol),
                subtitle: Text(
                  '${position.side} · ${position.size} @ '
                  '${position.avgPrice.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '${position.unrealisedPnl >= 0 ? '+' : ''}'
                  '${position.unrealisedPnl.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: position.unrealisedPnl >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
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
