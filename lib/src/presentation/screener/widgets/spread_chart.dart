import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Live spread chart: `net_pct` line + `baseline_pct` reference line, with dots
/// marking points where the spread was not fully executable (`capped_by_depth`).
///
/// Values are parsed decimal-safe and converted to `double` only for pixel
/// coordinates (rendering, not money math), then shown as percent.
class SpreadChart extends StatelessWidget {
  final List<SpreadPoint> points;

  const SpreadChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(child: Text('Накопление данных…'));
    }

    final scheme = Theme.of(context).colorScheme;
    final netSpots = <FlSpot>[];
    final baselineSpots = <FlSpot>[];
    final cappedX = <double>{};

    for (final point in points) {
      final x = point.tsMs.toDouble();
      final net = _pct(point.netPct);
      if (net == null) continue;
      netSpots.add(FlSpot(x, net));
      if (point.cappedByDepth) cappedX.add(x);
      final baseline = _pct(point.baselinePct);
      if (baseline != null) baselineSpots.add(FlSpot(x, baseline));
    }
    if (netSpots.length < 2) {
      return const Center(child: Text('Накопление данных…'));
    }

    final minX = netSpots.first.x;
    final maxX = netSpots.last.x;
    final ys = [
      ...netSpots.map((s) => s.y),
      ...baselineSpots.map((s) => s.y),
    ];
    var minY = ys.reduce((a, b) => a < b ? a : b);
    var maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() * 0.15).clamp(0.05, double.infinity);
    minY -= pad;
    maxY += pad;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: ((maxX - minX) / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _hms(value.toInt()),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(3)}%',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          if (baselineSpots.length >= 2)
            LineChartBarData(
              spots: baselineSpots,
              isCurved: false,
              color: scheme.outline,
              barWidth: 1,
              dashArray: const [4, 4],
              dotData: const FlDotData(show: false),
            ),
          LineChartBarData(
            spots: netSpots,
            isCurved: false,
            color: scheme.primary,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => cappedX.contains(spot.x),
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: scheme.error,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  /// Decimal-safe parse → percent as double (for pixels only).
  static double? _pct(String? fraction) {
    final value = Decimals.parse(fraction);
    return value == null ? null : value.toDouble() * 100;
  }

  static String _hms(int tsMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(tsMs);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
