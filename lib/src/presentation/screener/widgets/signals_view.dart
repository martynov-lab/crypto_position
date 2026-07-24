import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Live signals as a table keyed by instrument (newest wins), best quality
/// first. Falls back to a `GET /summary` snapshot before the first event.
class SignalsView extends StatelessWidget {
  final ValueListenable<List<SignalEvent>> signals;
  final ValueListenable<List<SummaryEntry>> summary;
  final Future<void> Function() onRefresh;

  /// Read fresh on each rebuild so the `/summary` fallback re-filters after a
  /// filter change (deny list + spread band applied client-side).
  final ClientConfig Function() configOf;


  /// Tapping a coin opens its live spread chart, pinned to the signal's pair
  /// (long = buy_exchange, short = sell_exchange). [entrySpreadPct] is the
  /// signal's entry spread as a plain percent number (e.g. `0.82` for 0.82%),
  /// used to seed the calculator's "Спред входа" field.
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
    double? entrySpreadPct,
  ) onTap;

  const SignalsView({
    super.key,
    required this.signals,
    required this.summary,
    required this.onRefresh,
    required this.configOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SignalEvent>>(
      valueListenable: signals,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return _SummaryFallback(
            summary: summary,
            configOf: configOf,
            onTap: onTap,
          );
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
  final ClientConfig Function() configOf;
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
    double? entrySpreadPct,
  ) onTap;

  const _SummaryFallback({
    required this.summary,
    required this.configOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SummaryEntry>>(
      valueListenable: summary,
      builder: (context, allRows, _) {
        final rows = _applyLocalFilters(allRows, configOf());
        if (rows.isEmpty) {
          return const Center(child: Text('Ожидание сигналов…'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _FallbackBanner(),
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
                          row.sellExchange, _entrySpreadPercent(row.netPct));
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

/// Converts a wire fraction (e.g. `"0.0082"`) to the plain percent number the
/// calculator's "Спред входа" field expects (e.g. `0.82`), or `null` when
/// unparsable/absent.
double? _entrySpreadPercent(String fraction) =>
    double.tryParse(Decimals.toPercentInput(fraction) ?? '');

/// Parses a `BASE/QUOTE` summary string into an [Instrument] (perp).
Instrument? _instrumentFromPair(String pair) {
  final parts = pair.split('/');
  if (parts.length != 2) return null;
  return Instrument(base: parts[0], quote: parts[1], kind: 'perp');
}

/// The `/summary` snapshot is filtered server-side by its *default* config, so
/// the client's deny list and spread band still have to be applied locally
/// before rendering. Volume/OI can't be filtered here — `/summary` carries no
/// volume field. Band edges are only applied when the user actually set them.
List<SummaryEntry> _applyLocalFilters(
  List<SummaryEntry> rows,
  ClientConfig config,
) {
  final deny = {
    for (final symbol in config.denySymbols ?? const <String>[])
      symbol.toUpperCase(),
  };
  final minNet = Decimals.parse(config.minNetSpreadPct);
  final maxNet = Decimals.parse(config.maxNetSpreadPct);
  return rows.where((row) {
    final base = row.instrument.split('/').first.toUpperCase();
    if (deny.contains(base)) return false;
    final net = Decimals.parse(row.netPct);
    if (net != null) {
      if (minNet != null && net < minNet) return false;
      if (maxNet != null && net > maxNet) return false;
    }
    return true;
  }).toList();
}

/// Colored banner making it unmistakable that these rows are an overview
/// snapshot (best spread per coin from `/summary`), not live signals.
class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Обзорный снимок /summary — это не живые сигналы. '
              'Лучший спред по каждой монете; обновляется по запросу.',
              style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final SignalEvent event;
  final void Function(
    BuildContext context,
    Instrument instrument,
    String? longExchange,
    String? shortExchange,
    double? entrySpreadPct,
  ) onTap;

  const _SignalCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spread = event.spread;
    final theme = Theme.of(context);
    return Card(
      // Alert-level signals (crossed alert_net_spread_pct) get a highlighted
      // border — info-level ones (list-only, no notification) stay plain.
      shape: event.isAlert
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.error, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: () => onTap(context, spread.instrument, spread.buyExchange,
            spread.sellExchange, _entrySpreadPercent(spread.netPct)),
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
                if (event.isAlert) ...[
                  const _AlertChip(),
                  const SizedBox(width: 6),
                ],
                if (event.qualityScore != null)
                  _QualityChip(event.qualityScore!),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'купить ${spread.buyExchange} @ ${Decimals.amount(spread.vwapBuy)}\n'
                    'продать ${spread.sellExchange} @ ${Decimals.amount(spread.vwapSell)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // round_trip_pct is the trade's actual profit (four taker fees
                // + unwind level + funding); net_pct is only the entry half.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PercentLabel(fraction: spread.roundTripPct, large: true),
                    Tooltip(
                      message:
                          'Спред на входе в сделку — без учёта комиссий и '
                          'условий закрытия. Крупная цифра выше — прибыль за '
                          'весь круг (вход и выход, все комиссии, фандинг): '
                          'ориентируйтесь на неё, а не на эту.',
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 8),
                      child: Text(
                        'вход ${Decimals.percent(spread.netPct)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          decorationColor: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag('объём ${Decimals.amount(spread.executableNotional)}'),
                if (spread.expectedProfitQuote.isNotEmpty)
                  _Tag('~${Decimals.amount(spread.expectedProfitQuote)} USDT'),
                if (spread.cappedByDepth)
                  const _Tag(
                    'мало объёма в стакане',
                    warning: true,
                    tooltip:
                        'В стакане недостаточно объёма по нужной цене, чтобы '
                        'исполнить сделку на весь расчётный объём — реальный '
                        'объём и прибыль могут оказаться меньше показанных.',
                  ),
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
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final episodeSec = (dynamics.episodeMs / 1000).toStringAsFixed(1);
    final spikeStrength = Decimals.amount(dynamics.zScore);
    return Tooltip(
      message:
          '«Обычно» — типичный спред этой монеты в спокойное время. '
          '«Сейчас» — спред в этот момент. «Держится» — сколько секунд он уже '
          'расширен. «Сила всплеска» показывает, насколько сильно текущий '
          'спред отличается от обычного — чем выше число, тем более '
          'выраженный и вероятно настоящий скачок, а не случайный шум. '
          'Посчитано по ${dynamics.sampleCount} последним замерам, из них '
          '${dynamics.baselineSamples} использованы для расчёта «обычного» '
          'уровня.',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 10),
      child: Text(
        'Обычно ~${Decimals.percent(dynamics.baselinePct)} → '
        'сейчас ${Decimals.percent(dynamics.currentPct)}  ·  '
        'держится $episodeSec с  ·  '
        'сила всплеска $spikeStrength',
        style: style?.copyWith(
          color: color,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: Theme.of(context).colorScheme.outline,
        ),
      ),
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

/// Marks a signal that crossed `alert_net_spread_pct` — the level the client
/// notifies on (vs. `info`, list-only).
class _AlertChip extends StatelessWidget {
  const _AlertChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'ALERT',
        style: TextStyle(
          color: scheme.onError,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String score;

  const _QualityChip(this.score);

  @override
  Widget build(BuildContext context) {
    final rounded = double.tryParse(score)?.round().toString() ?? score;
    return Tooltip(
      message:
          'Оценка качества сигнала от 0 до 100. Учитывает: прибыль за круг '
          'и доступный объём (важнее всего), силу всплеска спреда, '
          'стабильность обычного уровня спреда, свежесть котировок и '
          'число бирж, где торгуется монета. Чем выше число — тем надёжнее '
          'возможность.',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Качество $rounded',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool warning;

  /// When set, tapping the tag shows a plain-language explanation.
  final String? tooltip;

  const _Tag(this.text, {this.warning = false, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = warning ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = warning ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
    );
    if (tooltip == null) return chip;
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: chip,
    );
  }
}
