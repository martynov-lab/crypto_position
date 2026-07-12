import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';
import 'package:ui_kit/ui_kit.dart';

/// Browsable traded-instrument catalog: which coins list on which venues.
/// Filters by base-asset substring.
class UniverseView extends StatefulWidget {
  final ValueListenable<List<InstrumentCoverage>> universe;

  const UniverseView({super.key, required this.universe});

  @override
  State<UniverseView> createState() => _UniverseViewState();
}

class _UniverseViewState extends State<UniverseView> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: AppTextField(
            controller: _controller,
            prefixIcon: const Icon(Icons.search),
            hintText: 'Поиск монеты (например, BTC)',
            onChanged: (value) =>
                setState(() => _query = value.trim().toUpperCase()),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<InstrumentCoverage>>(
            valueListenable: widget.universe,
            builder: (context, rows, _) {
              final filtered = _query.isEmpty
                  ? rows
                  : rows
                      .where((row) => row.base.toUpperCase().contains(_query))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('Каталог пуст'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _CoverageTile(coverage: filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoverageTile extends StatelessWidget {
  final InstrumentCoverage coverage;

  const _CoverageTile({required this.coverage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coverage.pair,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${coverage.coverage} площадок'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final exchange in coverage.exchanges)
                  Chip(
                    label: Text(exchange),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
