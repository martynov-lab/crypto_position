import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart'
    show SpreadSample;
import 'package:crypto_position/src/presentation/arbitrage_calculator/widgets/spread_line_chart.dart';
import 'package:crypto_position/src/presentation/screener/coin_chart_wm.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:screener/screener.dart';

/// Route argument for the coin chart: the instrument plus the pinned long/short
/// pair taken from the tapped signal (long = buy_exchange, short = sell).
class CoinChartArgs {
  final Instrument instrument;
  final String? longExchange;
  final String? shortExchange;

  const CoinChartArgs({
    required this.instrument,
    this.longExchange,
    this.shortExchange,
  });
}

/// Coin detail screen with the live In/Out spread chart + funding panel. Pushed
/// over the bottom nav, so it carries its own [Scaffold] + back button.
class CoinChartScreen extends ElementaryWidget<CoinChartWm> {
  final CoinChartArgs args;

  CoinChartScreen({required this.args, super.key})
      : super(
          (context) => coinChartWmFactory(
            context: context,
            instrument: args.instrument,
            longExchange: args.longExchange,
            shortExchange: args.shortExchange,
          ),
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
          return ValueListenableBuilder<List<SpreadPoint>>(
            valueListenable: wm.points,
            builder: (context, points, _) {
              return ValueListenableBuilder<WatchMeta?>(
                valueListenable: wm.meta,
                builder: (context, meta, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: wm.bucketMs,
                    builder: (context, bucket, _) {
                      final view = downsampleSpread(points, bucket);
                      return ListView(
                        children: [
                          _Header(wm: wm, points: view, meta: meta),
                          _TimeframeSelector(
                            current: bucket,
                            onSelect: wm.setTimeframe,
                          ),
                          SizedBox(
                            height: 320,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 0, 4),
                              child: view.isEmpty
                                  ? _WaitingForData(
                                      connectionState: wm.connectionState,
                                    )
                                  : SpreadLineChart(
                                      // Entry (In) spread as the single line;
                                      // the wm already downsampled by bucket,
                                      // so no extra bucketing in the chart.
                                      series: [
                                        for (final p in view)
                                          if (Decimals.parse(p.entryPct)
                                              case final v?)
                                            SpreadSample(
                                              p.tsMs,
                                              v.toDouble() * 100,
                                            ),
                                      ],
                                      timeframeMin: 0,
                                      buyLabel: meta?.longExchange ??
                                          wm.longExchange,
                                      sellLabel: meta?.shortExchange ??
                                          wm.shortExchange,
                                    ),
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: ArbitrageCalculator(
                              embedded: true,
                              initialBase: args.instrument.base,
                              initialExchange1:
                                  _exchangeByName(args.longExchange),
                              initialExchange2:
                                  _exchangeByName(args.shortExchange),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Maps a screener exchange name (`bybit`, `okx`, …) to the app's
  /// [ExchangeId] by its stable key; null when unknown.
  static ExchangeId? _exchangeByName(String? name) {
    final key = name?.toLowerCase();
    for (final e in ExchangeId.values) {
      if (e.key == key) return e;
    }
    return null;
  }

}

/// Pinned pair + current In/Out values above the chart.
class _Header extends StatelessWidget {
  final CoinChartWm wm;
  final List<SpreadPoint> points;
  final WatchMeta? meta;

  const _Header({required this.wm, required this.points, required this.meta});

  @override
  Widget build(BuildContext context) {
    final long = meta?.longExchange ?? wm.longExchange;
    final short = meta?.shortExchange ?? wm.shortExchange;
    final latest = points.isEmpty ? null : points.last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (long != null && short != null)
            Expanded(
              child: Text(
                'long $long → short $short',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            const Spacer(),
          if (latest != null) ...[
            _ValueChip(
              label: 'вход',
              value: Decimals.percent(latest.entryPct),
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            if (latest.outPct != null)
              _ValueChip(
                label: 'выход',
                value: Decimals.percent(latest.outPct!),
                color: Colors.red,
              ),
            if (latest.cappedByDepth) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          ],
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
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

/// Timeframe picker: each option buckets the raw samples into one point per
/// interval (0 = raw, per-sample).
class _TimeframeSelector extends StatelessWidget {
  final int current;
  final void Function(int bucketMs) onSelect;

  const _TimeframeSelector({required this.current, required this.onSelect});

  static const _options = <(String, int)>[
    ('1с', 0),
    ('30с', 30000),
    ('1м', 60000),
    ('5м', 300000),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          for (final (label, ms) in _options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: current == ms,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onSelect(ms),
              ),
            ),
        ],
      ),
    );
  }
}
