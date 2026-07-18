import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Live single-line chart of the spread (leg2 vs leg1) over a rolling window.
class SpreadLineChart extends StatelessWidget {
  final List<SpreadSample> series;

  const SpreadLineChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return const Center(child: Text('Накопление данных…'));
    }

    final spots = [
      for (final s in series) FlSpot(s.tsMs.toDouble(), s.spreadPct),
    ];

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 1.4,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
