import 'package:crypto_position/src/presentation/screener/coin_chart_wm.dart';
import 'package:crypto_position/src/presentation/screener/widgets/spread_chart.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:screener/screener.dart';

/// Coin detail screen with the live spread chart. Pushed over the bottom nav,
/// so it carries its own [Scaffold] + back button.
class CoinChartScreen extends ElementaryWidget<CoinChartWm> {
  final Instrument instrument;

  CoinChartScreen({required this.instrument, super.key})
      : super(
          (context) =>
              coinChartWmFactory(context: context, instrument: instrument),
        );

  @override
  Widget build(CoinChartWm wm) {
    return Scaffold(
      appBar: AppBar(title: Text('${wm.instrument.pair} · спред')),
      body: ValueListenableBuilder<bool>(
        valueListenable: wm.capExceeded,
        builder: (context, capExceeded, _) {
          if (capExceeded) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Достигнут лимит одновременных графиков (3). '
                  'Закройте другой график и попробуйте снова.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              _Header(wm: wm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: ValueListenableBuilder<List<SpreadPoint>>(
                    valueListenable: wm.points,
                    builder: (context, points, _) {
                      if (points.isEmpty) {
                        return _WaitingForData(
                          connectionState: wm.connectionState,
                        );
                      }
                      return SpreadChart(points: points);
                    },
                  ),
                ),
              ),
              const _Legend(),
            ],
          );
        },
      ),
    );
  }
}

/// Shows the newest point's headline numbers above the chart.
class _Header extends StatelessWidget {
  final CoinChartWm wm;

  const _Header({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SpreadPoint>>(
      valueListenable: wm.points,
      builder: (context, points, _) {
        if (points.isEmpty) return const SizedBox.shrink();
        final latest = points.last;
        final negative = Decimals.isNegative(latest.netPct);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                Decimals.percent(latest.netPct),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: negative ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              if (latest.buyExchange != null && latest.sellExchange != null)
                Expanded(
                  child: Text(
                    '${latest.buyExchange} → ${latest.sellExchange}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (latest.cappedByDepth)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'мираж',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WaitingForData extends StatelessWidget {
  final ValueListenable<WsConnectionState> connectionState;

  const _WaitingForData({required this.connectionState});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WsConnectionState>(
      valueListenable: connectionState,
      builder: (context, state, _) {
        if (state != WsConnectionState.connected) {
          return const Center(child: Text('Нет соединения со скринером'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _LegendItem(color: scheme.primary, label: 'чистый спред'),
          _LegendItem(color: scheme.outline, label: 'baseline'),
          _LegendItem(color: scheme.error, label: 'ограничено глубиной'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
