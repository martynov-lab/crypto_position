import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Live signals as a table keyed by instrument (newest wins), best quality
/// first. Falls back to a `GET /summary` snapshot before the first event.
class SignalsView extends StatelessWidget {
  final ValueListenable<List<SignalEvent>> signals;
  final ValueListenable<List<SummaryEntry>> summary;
  final Future<void> Function() onRefresh;

  /// Tapping a coin opens its live spread chart, pinned to the signal's pair
  /// (long = buy_exchange, short = sell_exchange).
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
  ) onTap;

  const SignalsView({
    super.key,
    required this.signals,
    required this.summary,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SignalEvent>>(
      valueListenable: signals,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return _SummaryFallback(summary: summary, onTap: onTap);
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) =>
                _SignalCard(event: events[index], onTap: onTap),
          ),
        );
      },
    );
  }
}

class _SummaryFallback extends StatelessWidget {
  final ValueListenable<List<SummaryEntry>> summary;
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
  ) onTap;

  const _SummaryFallback({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SummaryEntry>>(
      valueListenable: summary,
      builder: (context, rows, _) {
        if (rows.isEmpty) {
          return const Center(child: Text('Ожидание сигналов…'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Снимок /summary (нет живых сигналов)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(row.instrument),
                  subtitle: Text(
                    'купить ${row.buyExchange} → продать ${row.sellExchange}'
                    '  ·  ${row.coverage} площадок',
                  ),
                  trailing: _PercentLabel(fraction: row.netPct),
                  onTap: () {
                    final instrument = _instrumentFromPair(row.instrument);
                    if (instrument != null) {
                      onTap(context, instrument, row.buyExchange,
                          row.sellExchange);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Parses a `BASE/QUOTE` summary string into an [Instrument] (perp).
Instrument? _instrumentFromPair(String pair) {
  final parts = pair.split('/');
  if (parts.length != 2) return null;
  return Instrument(base: parts[0], quote: parts[1], kind: 'perp');
}

class _SignalCard extends StatelessWidget {
  final SignalEvent event;
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
  ) onTap;

  const _SignalCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spread = event.spread;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => onTap(context, spread.instrument, spread.buyExchange,
            spread.sellExchange),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spread.instrument.pair,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (event.qualityScore != null) _QualityChip(event.qualityScore!),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'купить ${spread.buyExchange} @ ${spread.vwapBuy}\n'
                    'продать ${spread.sellExchange} @ ${spread.vwapSell}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                _PercentLabel(fraction: spread.netPct, large: true),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag('объём ${spread.executableNotional}'),
                if (spread.cappedByDepth)
                  const _Tag('ограничено глубиной', warning: true),
                if (event.funding != null)
                  _Tag(
                    'funding ${Decimals.percent(event.funding!.diffApr)} '
                    '(L:${event.funding!.longExchange}/S:${event.funding!.shortExchange})',
                  ),
              ],
            ),
              if (event.dynamics != null) ...[
                const SizedBox(height: 8),
                _DynamicsRow(event.dynamics!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicsRow extends StatelessWidget {
  final SpreadDynamics dynamics;

  const _DynamicsRow(this.dynamics);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Text(
      'база ${Decimals.percent(dynamics.baselinePct)} → '
      'сейчас ${Decimals.percent(dynamics.currentPct)}  ·  '
      'z ${dynamics.zScore}  ·  '
      'эпизод ${(dynamics.episodeMs / 1000).toStringAsFixed(1)}с  ·  '
      'n=${dynamics.sampleCount}',
      style: style?.copyWith(color: Theme.of(context).colorScheme.outline),
    );
  }
}

class _PercentLabel extends StatelessWidget {
  final String fraction;
  final bool large;

  const _PercentLabel({required this.fraction, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = Decimals.isNegative(fraction) ? Colors.red : Colors.green;
    return Text(
      Decimals.percent(fraction),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: large ? 18 : 15,
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String score;

  const _QualityChip(this.score);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Q $score',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool warning;

  const _Tag(this.text, {this.warning = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = warning ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = warning ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
    );
  }
}
