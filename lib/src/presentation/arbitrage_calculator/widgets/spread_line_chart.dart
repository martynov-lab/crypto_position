import 'dart:math' as math;

import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Live single-line spread chart (leg2 vs leg1), TradingView-style dark look.
///
/// Raw 2s samples are bucketed by [timeframeMin] (one point per bucket, last
/// value wins; `0` = raw ticks). The vertical axis is centered on 0 with dotted
/// reference lines at 0 and ±0.5 / ±0.8; the buy/sell venues are labelled in the
/// corner.
///
/// Both rulers are independently zoomable: scroll or drag vertically over the
/// **right** ruler to stretch/compress vertically; scroll or drag horizontally
/// over the **bottom** ruler to compress/expand the time window. Double-tap a
/// ruler to reset that axis.
class SpreadLineChart extends StatefulWidget {
  final List<SpreadSample> series;
  final int timeframeMin;
  final String? buyLabel;
  final String? sellLabel;

  const SpreadLineChart({
    super.key,
    required this.series,
    required this.timeframeMin,
    this.buyLabel,
    this.sellLabel,
  });

  @override
  State<SpreadLineChart> createState() => _SpreadLineChartState();
}

// Plot-area insets: reserved space for the right (value) and bottom (time)
// rulers, plus a little breathing room top/left.
const double _rightAxis = 52;
const double _bottomAxis = 22;
const double _topPad = 8;
const double _leftPad = 8;

// Zoom limits (multipliers over the auto-fitted base range).
const double _minYZoom = 0.25;
const double _maxYZoom = 12;
const double _maxXZoom = 30; // max horizontal zoom-in (smallest window)
const double _maxXOut = 5; // max compress: window up to N× the data span

// Fixed dark palette so the chart looks the same regardless of app theme.
const _bg = Color(0xFF0B0E11);
const _grid = Color(0x14FFFFFF);
const _axisText = Color(0xFF9AA0A6);
const _lineColor = Color(0xFF2BD5A5);
const _buyColor = Color(0xFF2BD576);
const _sellColor = Color(0xFFF6465D);

/// Fixed dotted reference levels (percent) and their colors.
const _refLevels = <(double, Color)>[
  (0.8, Color(0x552BD576)),
  (0.5, Color(0x66E8C34D)),
  (0.0, Color(0x66FFFFFF)),
  (-0.5, Color(0x66E8C34D)),
  (-0.8, Color(0x55F6465D)),
];

class _SpreadLineChartState extends State<SpreadLineChart> {
  /// Vertical zoom multiplier over the auto-fitted (0-centered) range.
  double _yZoom = 1;

  /// Visible time window in ms (right-anchored). Null = auto-fit all data.
  double? _xSpanMs;

  @override
  Widget build(BuildContext context) {
    final points = _bucketByTimeframe(widget.series, widget.timeframeMin);
    if (points.length < 2) {
      return const _ChartBackground(child: Text('Накопление данных…'));
    }

    final spots = [
      for (final s in points) Offset(s.tsMs.toDouble(), s.spreadPct),
    ];

    // --- Y range: centered on 0, fitting the data but always showing the
    // outermost reference line (±0.8), scaled by the vertical zoom.
    var maxAbs = 0.8;
    for (final s in spots) {
      maxAbs = math.max(maxAbs, s.dy.abs());
    }
    final half = maxAbs * 1.15 / _yZoom;
    final minY = -half;
    final maxY = half;
    final interval = _niceInterval((maxY - minY) / 6);

    // --- X range: right-anchored to the newest sample; a fixed window once the
    // user zooms, otherwise auto-fit all data.
    final firstX = spots.first.dx;
    final lastX = spots.last.dx;
    final fullSpan = math.max(lastX - firstX, 1).toDouble();
    final span = (_xSpanMs ?? fullSpan).clamp(
      fullSpan / _maxXZoom,
      fullSpan * _maxXOut,
    );
    final geom = _ChartGeometry(
      minX: lastX - span,
      maxX: lastX,
      minY: minY,
      maxY: maxY,
      interval: interval,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _ChartPainter(
            spots: spots,
            geom: geom,
            buyLabel: widget.buyLabel,
            sellLabel: widget.sellLabel,
          ),
        ),
        // Right ruler → vertical zoom.
        Positioned(
          top: 0,
          bottom: _bottomAxis,
          right: 0,
          width: _rightAxis,
          child: _RulerZoomArea(
            axis: _RulerAxis.vertical,
            onZoom: _zoomY,
            onReset: () => setState(() => _yZoom = 1),
          ),
        ),
        // Bottom ruler → horizontal zoom.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _bottomAxis,
          child: _RulerZoomArea(
            axis: _RulerAxis.horizontal,
            onZoom: (delta) => _zoomX(delta, fullSpan),
            onReset: () => setState(() => _xSpanMs = null),
          ),
        ),
      ],
    );
  }

  /// Positive [dy] (scrolling/dragging down) compresses; negative expands.
  void _zoomY(double dy) {
    final next = (_yZoom * math.exp(-dy * 0.01)).clamp(_minYZoom, _maxYZoom);
    if (next == _yZoom) return;
    setState(() => _yZoom = next);
  }

  /// Positive [delta] (dragging right / scrolling down) compresses by widening
  /// the window; negative expands it.
  void _zoomX(double delta, double fullSpan) {
    final current = _xSpanMs ?? fullSpan;
    final next = (current * math.exp(delta * 0.01)).clamp(
      fullSpan / _maxXZoom,
      fullSpan * _maxXOut,
    );
    if (next == _xSpanMs) return;
    setState(() => _xSpanMs = next);
  }

  /// Groups raw samples into [tfMin]-minute buckets, keeping each bucket's last
  /// value. `tfMin <= 0` means raw ticks (no bucketing).
  static List<SpreadSample> _bucketByTimeframe(
    List<SpreadSample> raw,
    int tfMin,
  ) {
    if (raw.isEmpty || tfMin <= 0) return raw;
    final tfMs = tfMin * 60 * 1000;
    final out = <SpreadSample>[];
    for (final s in raw) {
      final key = (s.tsMs ~/ tfMs) * tfMs;
      if (out.isNotEmpty && out.last.tsMs == key) {
        out[out.length - 1] = SpreadSample(key, s.spreadPct);
      } else {
        out.add(SpreadSample(key, s.spreadPct));
      }
    }
    return out;
  }

  /// A "nice" axis step (1/2/5 × 10ⁿ) close to [rough].
  static double _niceInterval(double rough) {
    if (rough <= 0 || !rough.isFinite) return 1;
    final pow10 = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final n = rough / pow10;
    final niceN = n < 1.5
        ? 1.0
        : n < 3
        ? 2.0
        : n < 7
        ? 5.0
        : 10.0;
    return niceN * pow10;
  }
}

/// Simple dark placeholder shown before enough data has accumulated.
class _ChartBackground extends StatelessWidget {
  final Widget child;
  const _ChartBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Center(
        child: DefaultTextStyle(
          style: const TextStyle(color: _axisText, fontSize: 12),
          child: child,
        ),
      ),
    );
  }
}

enum _RulerAxis { vertical, horizontal }

/// Transparent strip that turns scroll / drag along its [axis] into a zoom delta
/// (positive = compress) and a double-tap into a reset.
class _RulerZoomArea extends StatelessWidget {
  final _RulerAxis axis;
  final void Function(double delta) onZoom;
  final VoidCallback onReset;

  const _RulerZoomArea({
    required this.axis,
    required this.onZoom,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == _RulerAxis.horizontal;
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) onZoom(event.scrollDelta.dy);
      },
      child: MouseRegion(
        cursor: horizontal
            ? SystemMouseCursors.resizeLeftRight
            : SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: horizontal ? null : (e) => onZoom(e.delta.dy),
          onHorizontalDragUpdate: horizontal ? (e) => onZoom(e.delta.dx) : null,
          onDoubleTap: onReset,
        ),
      ),
    );
  }
}

/// Value/pixel geometry for one frame.
class _ChartGeometry {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double interval;

  const _ChartGeometry({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.interval,
  });
}

class _ChartPainter extends CustomPainter {
  final List<Offset> spots;
  final _ChartGeometry geom;
  final String? buyLabel;
  final String? sellLabel;

  _ChartPainter({
    required this.spots,
    required this.geom,
    required this.buyLabel,
    required this.sellLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    final plot = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightAxis,
      size.height - _bottomAxis,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    _drawGridAndValueAxis(canvas, plot);
    _drawReferenceLines(canvas, plot);
    _drawTimeAxis(canvas, plot);

    canvas.save();
    canvas.clipRect(plot);
    _drawAreaAndLine(canvas, plot);
    canvas.restore();

    _drawLegend(canvas, plot);
  }

  // --- coordinate mapping ---------------------------------------------------

  double _xToPx(Rect plot, double x) {
    final span = geom.maxX - geom.minX;
    if (span <= 0) return plot.left;
    return plot.left + (x - geom.minX) / span * plot.width;
  }

  double _yToPx(Rect plot, double y) {
    final span = geom.maxY - geom.minY;
    if (span <= 0) return plot.center.dy;
    return plot.top + (geom.maxY - y) / span * plot.height;
  }

  double _pxToX(Rect plot, double px) =>
      geom.minX + (px - plot.left) / plot.width * (geom.maxX - geom.minX);

  // --- pieces ---------------------------------------------------------------

  void _drawGridAndValueAxis(Canvas canvas, Rect plot) {
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    final first = (geom.minY / geom.interval).ceil();
    final last = (geom.maxY / geom.interval).floor();
    for (var i = first; i <= last; i++) {
      final value = i * geom.interval;
      final y = _yToPx(plot, value);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(
        canvas,
        _fmtPct(value, geom.interval),
        Offset(plot.right + 6, y),
        color: _axisText,
        anchorY: _AnchorY.center,
      );
    }
  }

  /// Dotted horizontal lines at 0 and ±0.5 / ±0.8, with colored right-edge tags.
  void _drawReferenceLines(Canvas canvas, Rect plot) {
    for (final (value, color) in _refLevels) {
      if (value < geom.minY || value > geom.maxY) continue;
      final y = _yToPx(plot, value);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;
      _dashedSegment(canvas, Offset(plot.left, y), Offset(plot.right, y), paint);
    }
  }

  void _drawTimeAxis(Canvas canvas, Rect plot) {
    const ticks = 5;
    for (var i = 0; i <= ticks; i++) {
      final x = plot.left + plot.width * i / ticks;
      final ts = _pxToX(plot, x).toInt();
      final align = i == 0
          ? TextAlign.left
          : i == ticks
          ? TextAlign.right
          : TextAlign.center;
      _text(
        canvas,
        _hms(ts),
        Offset(x, plot.bottom + 5),
        color: _axisText,
        align: align,
        anchorY: _AnchorY.top,
      );
    }
  }

  void _drawAreaAndLine(Canvas canvas, Rect plot) {
    if (spots.length < 2) return;

    final pixels = [
      for (final s in spots) Offset(_xToPx(plot, s.dx), _yToPx(plot, s.dy)),
    ];

    // Gradient fill from the line down to the plot bottom.
    final fill = Path()..moveTo(pixels.first.dx, plot.bottom);
    for (final p in pixels) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(pixels.last.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x662BD5A5), Color(0x333B2BD5), Color(0x00000000)],
        ).createShader(plot),
    );

    // The line itself.
    final line = Path()..moveTo(pixels.first.dx, pixels.first.dy);
    for (final p in pixels.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _lineColor
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Corner legend: which venue to buy on (green) and sell on (red).
  void _drawLegend(Canvas canvas, Rect plot) {
    final lines = <(String, Color)>[
      if (buyLabel != null) ('▲ Купить: $buyLabel', _buyColor),
      if (sellLabel != null) ('▼ Продать: $sellLabel', _sellColor),
    ];
    if (lines.isEmpty) return;
    var y = plot.top + 4;
    for (final (text, color) in lines) {
      final tp = _layout(text, color, 11, FontWeight.w600);
      tp.paint(canvas, Offset(plot.left + 4, y));
      y += tp.height + 2;
    }
  }

  // --- primitives -----------------------------------------------------------

  void _dashedSegment(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dash = 3,
    double gap = 3,
  }) {
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final end = math.min(drawn + dash, total);
      canvas.drawLine(from + dir * drawn, from + dir * end, paint);
      drawn = end + gap;
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required Color color,
    TextAlign align = TextAlign.left,
    _AnchorY anchorY = _AnchorY.top,
  }) {
    final tp = _layout(text, color, 10, FontWeight.w400);
    var dx = at.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right) dx -= tp.width;
    var dy = at.dy;
    if (anchorY == _AnchorY.center) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  TextPainter _layout(String text, Color color, double size, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }

  /// Percent label with just enough decimals for the tick [interval].
  static String _fmtPct(double value, double interval) {
    final decimals = interval >= 1
        ? 0
        : interval >= 0.1
        ? 1
        : interval >= 0.01
        ? 2
        : 3;
    final shown = value.abs() < interval / 1000 ? 0.0 : value;
    return shown.toStringAsFixed(decimals);
  }

  static String _hms(int tsMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(tsMs);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.spots != spots ||
      old.buyLabel != buyLabel ||
      old.sellLabel != sellLabel ||
      old.geom.minX != geom.minX ||
      old.geom.maxX != geom.maxX ||
      old.geom.minY != geom.minY ||
      old.geom.maxY != geom.maxY;
}

enum _AnchorY { top, center }
