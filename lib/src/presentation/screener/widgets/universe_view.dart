import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';
import 'package:ui_kit/ui_kit.dart';

/// How the catalog is ordered.
enum _Sort { spread, coverage, name }

/// Browsable traded-instrument catalog: which coins list on which venues, with
/// the current best spread from `/summary` where there is one. Venues disabled
/// in the filters are hidden, and so are coins left with fewer than two — the
/// spread chart needs a pair. Tapping a row opens the coin's chart.
class UniverseView extends StatefulWidget {
  final ValueListenable<List<InstrumentCoverage>> universe;
  final ValueListenable<List<SummaryEntry>> summary;

  /// Notifies when the applied filters change, so the venue narrowing below
  /// re-runs. Read [enabledExchanges] fresh on each build.
  final Listenable filters;
  final Set<String> Function() enabledExchanges;

  /// Pull-to-refresh for the `/summary` snapshot the spread column comes from
  /// (it is fetched on connect only, so it goes stale while the tab is open).
  final Future<void> Function() onRefresh;

  final void Function(BuildContext context, InstrumentCoverage coverage) onTap;

  const UniverseView({
    super.key,
    required this.universe,
    required this.summary,
    required this.filters,
    required this.enabledExchanges,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  State<UniverseView> createState() => _UniverseViewState();
}

class _UniverseViewState extends State<UniverseView> {
  final _controller = TextEditingController();
  String _query = '';
  _Sort _sort = _Sort.spread;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: AppTextField(
            controller: _controller,
            prefixIcon: const Icon(Icons.search),
            hintText: 'Поиск монеты (например, BTC)',
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Очистить',
                    onPressed: _clearQuery,
                  ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toUpperCase()),
          ),
        ),
        _SortSelector(
          current: _sort,
          onSelect: (sort) => setState(() => _sort = sort),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              widget.universe,
              widget.summary,
              widget.filters,
            ]),
            builder: (context, _) {
              final rows = _rows();
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    widget.universe.value.isEmpty
                        ? 'Каталог пуст'
                        : 'Ничего не найдено',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _CoverageTile(
                    row: rows[index],
                    onTap: () => widget.onTap(context, rows[index].coverage),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Catalog narrowed to the enabled venues and the search query, joined with
  /// the `/summary` snapshot, in the selected order.
  List<_Row> _rows() {
    final enabled = widget.enabledExchanges();
    final summary = {
      for (final entry in widget.summary.value) entry.instrument: entry,
    };
    final rows = <_Row>[];
    for (final coverage in widget.universe.value) {
      if (_query.isNotEmpty && !coverage.base.toUpperCase().contains(_query)) {
        continue;
      }
      final venues = coverage.exchanges.where(enabled.contains).toList();
      if (venues.length < 2) continue;
      // The summary's best pair can sit on a venue the user switched off — its
      // spread would then be unreachable, so it is not shown.
      final entry = summary[coverage.pair];
      final reachable = entry != null &&
          venues.contains(entry.buyExchange) &&
          venues.contains(entry.sellExchange);
      rows.add(_Row(coverage: coverage, venues: venues, summary:
          reachable ? entry : null));
    }
    rows.sort(_compare);
    return rows;
  }

  int _compare(_Row a, _Row b) => switch (_sort) {
        // Rows without a live spread sort last, then alphabetically so the
        // order stays stable between /summary refreshes.
        _Sort.spread => switch ((a.netSort, b.netSort)) {
            (null, null) => a.coverage.base.compareTo(b.coverage.base),
            (null, _) => 1,
            (_, null) => -1,
            (final x?, final y?) => y.compareTo(x),
          },
        _Sort.coverage => b.venues.length.compareTo(a.venues.length),
        _Sort.name => a.coverage.base.compareTo(b.coverage.base),
      };
}

/// One rendered catalog row: the coin, its enabled venues and the current best
/// spread when the summary has a reachable one.
class _Row {
  final InstrumentCoverage coverage;
  final List<String> venues;
  final SummaryEntry? summary;

  const _Row({
    required this.coverage,
    required this.venues,
    required this.summary,
  });

  /// Ordering key only — the label always renders the raw decimal string, so
  /// the float here never reaches a displayed number.
  double? get netSort => double.tryParse(summary?.netPct ?? '');
}

class _SortSelector extends StatelessWidget {
  final _Sort current;
  final ValueChanged<_Sort> onSelect;

  const _SortSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (sort, label) in const [
            (_Sort.spread, 'По спреду'),
            (_Sort.coverage, 'По площадкам'),
            (_Sort.name, 'По названию'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text(label),
                selected: current == sort,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onSelect(sort),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoverageTile extends StatelessWidget {
  final _Row row;
  final VoidCallback onTap;

  const _CoverageTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final summary = row.summary;
    return Card(
      child: InkWell(
        onTap: onTap,
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
                      row.coverage.pair,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (summary != null) ...[
                    _PercentLabel(fraction: summary.netPct),
                    const SizedBox(width: 8),
                  ],
                  Text('${row.venues.length} площадок'),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: 4),
                Text(
                  'купить ${summary.buyExchange} → '
                  'продать ${summary.sellExchange}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final exchange in row.venues)
                    Chip(
                      label: Text(exchange),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PercentLabel extends StatelessWidget {
  final String fraction;

  const _PercentLabel({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Лучший спред по снимку /summary — не живое значение. '
          'Потяните список вниз, чтобы обновить.',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: Text(
        Decimals.percent(fraction),
        style: TextStyle(
          color: Decimals.isNegative(fraction) ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
