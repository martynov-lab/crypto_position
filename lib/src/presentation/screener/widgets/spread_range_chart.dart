import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Static (no zoom/pan) min/max/close view of `GET /spread/range`'s per-minute
/// buckets — "how wide does this coin's spread even get" over the last few
/// days. Each bucket draws as a vertical min↔max bar with a tick at the close
/// value; unlike the live [SpreadChart] this is a quick-glance summary, not a
/// trading chart, so it follows the app's Material theme instead of the fixed
/// dark palette.
class SpreadRangeChart extends StatelessWidget {
  final List<SpreadRangeBucket> buckets;

  const SpreadRangeChart({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    if (buckets.length < 2) {
      return const Center(child: Text('Недостаточно данных'));
    }
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.infinite,
      painter: _RangePainter(
        buckets: buckets,
        barColor: scheme.primary,
        closeColor: scheme.onSurface,
        gridColor: scheme.outlineVariant,
        textColor: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  final List<SpreadRangeBucket> buckets;
  final Color barColor;
  final Color closeColor;
  final Color gridColor;
  final Color textColor;

  _RangePainter({
    required this.buckets,
    required this.barColor,
    required this.closeColor,
    required this.gridColor,
    required this.textColor,
  });

  static const _rightAxis = 44.0;
  static const _bottomAxis = 18.0;
  static const _topPad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      4,
      _topPad,
      size.width - _rightAxis,
      size.height - _bottomAxis,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    var maxY = 0.0;
    for (final b in buckets) {
      final max = Decimals.parse(b.maxNetPct)?.toDouble();
      if (max != null) maxY = maxY < max ? max : maxY;
    }
    maxY = (maxY * 1.1).clamp(0.001, double.infinity);

    double yToPx(double v) => plot.bottom - (v / maxY) * plot.height;

    // Grid + value axis (0 and the top value).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final v in [0.0, maxY / 2, maxY]) {
      final y = yToPx(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(canvas, '${(v * 100).toStringAsFixed(2)}%',
          Offset(plot.right + 4, y));
    }

    final barWidth =
        (plot.width / buckets.length * 0.6).clamp(1.0, 6.0).toDouble();
    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final x = plot.left + plot.width * (i + 0.5) / buckets.length;
      final min = Decimals.parse(bucket.minNetPct)?.toDouble() ?? 0;
      final max = Decimals.parse(bucket.maxNetPct)?.toDouble() ?? 0;
      final close = Decimals.parse(bucket.closeNetPct)?.toDouble();

      canvas.drawLine(
        Offset(x, yToPx(min)),
        Offset(x, yToPx(max)),
        Paint()
          ..color = barColor.withValues(alpha: 0.45)
          ..strokeWidth = barWidth,
      );
      if (close != null) {
        canvas.drawLine(
          Offset(x - barWidth / 2, yToPx(close)),
          Offset(x + barWidth / 2, yToPx(close)),
          Paint()
            ..color = closeColor
            ..strokeWidth = 1.4,
        );
      }
    }

    // Time axis: first and last bucket timestamps.
    _text(canvas, _dm(buckets.first.tsMs), Offset(plot.left, plot.bottom + 3));
    _text(canvas, _dm(buckets.last.tsMs), Offset(plot.right, plot.bottom + 3),
        alignRight: true);
  }

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: textColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(alignRight ? at.dx - tp.width : at.dx, at.dy));
  }

  static String _dm(int tsMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(tsMs);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  bool shouldRepaint(_RangePainter old) => old.buckets != buckets;
}
