import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Funding sub-panel: two lines (long leg green, short leg red) over time, with
/// the current annualized rates and a live countdown to the next funding.
class FundingPanel extends StatefulWidget {
  final List<SpreadPoint> points;
  final WatchMeta? meta;

  const FundingPanel({super.key, required this.points, required this.meta});

  @override
  State<FundingPanel> createState() => _FundingPanelState();
}

class _FundingPanelState extends State<FundingPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown once a second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final longSpots = <FlSpot>[];
    final shortSpots = <FlSpot>[];
    for (final point in widget.points) {
      final x = point.tsMs.toDouble();
      final long = _pct(point.fundingLongPct);
      final short = _pct(point.fundingShortPct);
      if (long != null) longSpots.add(FlSpot(x, long));
      if (short != null) shortSpots.add(FlSpot(x, short));
    }
    final hasSeries = longSpots.length >= 2 || shortSpots.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Funding', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              if (meta?.fundingLongApr != null)
                _AprLabel(
                  color: Colors.green,
                  label: '${meta!.longExchange ?? 'long'} '
                      '${Decimals.percent(meta.fundingLongApr!, fractionDigits: 3)}',
                ),
              const SizedBox(width: 10),
              if (meta?.fundingShortApr != null)
                _AprLabel(
                  color: Colors.red,
                  label: '${meta!.shortExchange ?? 'short'} '
                      '${Decimals.percent(meta.fundingShortApr!, fractionDigits: 3)}',
                ),
              const SizedBox(width: 10),
              if (_countdown(meta) case final text?)
                Text('через $text',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (hasSeries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(3)}%',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    if (longSpots.length >= 2)
                      LineChartBarData(
                        spots: longSpots,
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 1.2,
                        dotData: const FlDotData(show: false),
                      ),
                    if (shortSpots.length >= 2)
                      LineChartBarData(
                        spots: shortSpots,
                        isCurved: false,
                        color: Colors.red,
                        barWidth: 1.2,
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// mm:ss (or hh:mm:ss) until [WatchMeta.nextFundingMs], or null.
  String? _countdown(WatchMeta? meta) {
    final next = meta?.nextFundingMs;
    if (next == null) return null;
    final remaining = next - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return '0:00';
    final total = remaining ~/ 1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  static double? _pct(String? fraction) {
    final value = Decimals.parse(fraction);
    return value == null ? null : value.toDouble() * 100;
  }
}

class _AprLabel extends StatelessWidget {
  final Color color;
  final String label;

  const _AprLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
