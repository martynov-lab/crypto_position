import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';

/// Live spread chart for a fixed pair, drawn with a custom [CustomPainter]
/// (TradingView-style dark look): **In** (entry, green solid) and **Out** (exit,
/// red dotted) lines, dotted reference lines at the latest In/Out with colored
/// price tags on the right edge, a faint grid, and dots where entry was capped
/// by depth.
///
/// The right and bottom rulers are independently zoomable: scroll or drag
/// vertically over the **right** ruler to stretch/compress the chart
/// vertically; do the same over the **bottom** ruler to stretch/compress it
/// horizontally. Double-tap a ruler to reset that axis.
///
/// Values are parsed decimal-safe and converted to `double` only for pixel
/// coordinates (rendering, not money math), then shown as percent.
class SpreadChart extends StatefulWidget {
  final List<SpreadPoint> points;

  const SpreadChart({super.key, required this.points});

  @override
  State<SpreadChart> createState() => _SpreadChartState();
}

/// Plot-area insets: reserved space for the right (value) and bottom (time)
/// rulers, plus a little breathing room top/left. Shared by the painter and the
/// gesture overlays so hit areas line up with what's drawn.
const double _rightAxis = 58;
const double _bottomAxis = 22;
const double _topPad = 8;
const double _leftPad = 8;

// Zoom limits (multipliers over the auto-fitted base range).
const double _minYZoom = 0.25;
const double _maxYZoom = 12;
const double _maxXZoom = 30; // max horizontal zoom-in (smallest visible window)
const double _maxXOut = 5; // max compress: window up to N× the data span (empty
// space fills the left as the data hugs the right edge)

/// Fixed dark palette so the chart looks the same regardless of app theme.
const _bg = Color(0xFF0B0E11);
const _grid = Color(0x14FFFFFF);
const _axisText = Color(0xFF9AA0A6);
const _inColor = Color(0xFF2BD576);
const _outColor = Color(0xFFF6465D);
const _crosshair = Color(0xB3FFFFFF);
const _tagText = Color(0xFF0B0E11);

class _SpreadChartState extends State<SpreadChart> {
  /// Independent zoom multipliers over the auto-fitted range.
  double _yZoom = 1;

  /// Visible time window in ms (right-anchored). Null = auto-fit all data;
  /// once the user zooms it becomes a fixed duration so new ticks only scroll
  /// it without changing density.
  double? _xSpanMs;

  /// Raw cursor position (widget pixels) for the crosshair, or null when away.
  Offset? _cursor;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.length < 2) {
      return const _ChartBackground(child: Text('Накопление данных…'));
    }

    // Build In/Out series in value space (x = tsMs, y = percent).
    final inSpots = <Offset>[];
    final outSpots = <Offset>[];
    final cappedX = <double>{};
    for (final point in points) {
      final x = point.tsMs.toDouble();
      final entry = _pct(point.entryPct);
      if (entry != null) {
        inSpots.add(Offset(x, entry));
        if (point.cappedByDepth) cappedX.add(x);
      }
      final out = _pct(point.outPct);
      if (out != null) outSpots.add(Offset(x, out));
    }
    if (inSpots.length < 2) {
      return const _ChartBackground(child: Text('Накопление данных…'));
    }

    // --- Y range: fit the real spread of both lines and always include 0
    // (perfect price match). Green sits above 0, red below, so 0 lands between
    // the lines and shows each one's true divergence — instead of the smaller
    // line being squished onto 0 by a symmetric range. Zoom scales the range
    // around its center.
    final ys = [...inSpots.map((s) => s.dy), ...outSpots.map((s) => s.dy)];
    var hi = math.max(ys.reduce(math.max), 0.0);
    var lo = math.min(ys.reduce(math.min), 0.0);
    var range = hi - lo;
    if (range < 0.02) range = 0.02;
    final pad = range * 0.08;
    hi += pad;
    lo -= pad;
    final center = (hi + lo) / 2;
    final half = (hi - lo) / 2 / _yZoom;
    final minY = center - half;
    final maxY = center + half;
    final interval = _niceInterval((maxY - minY) / 6);

    // --- X range: right-anchored to the newest sample. The visible window is a
    // fixed duration once the user zooms, so new ticks just scroll it left
    // without changing density; until then it auto-fits all data.
    final firstX = inSpots.first.dx;
    final lastX = inSpots.last.dx;
    final fullSpan = math.max(lastX - firstX, 1).toDouble();
    final span = (_xSpanMs ?? fullSpan)
        .clamp(fullSpan / _maxXZoom, fullSpan * _maxXOut);
    final maxX = lastX;
    final minX = maxX - span;

    final geom = _ChartGeometry(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      interval: interval,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ChartPainter(
                inSpots: inSpots,
                outSpots: outSpots,
                cappedX: cappedX,
                geom: geom,
                cursor: _cursor,
              ),
            ),
            // Crosshair layer: whole area; the ruler strips below sit on top and
            // claim their own gestures, so this only really acts on the plot.
            MouseRegion(
              opaque: false,
              onHover: (e) => _setCursor(e.localPosition),
              onExit: (_) => _setCursor(null),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (e) => _setCursor(e.localPosition),
                onPanUpdate: (e) => _setCursor(e.localPosition),
                onPanEnd: (_) => _setCursor(null),
              ),
            ),
            // Right ruler → vertical zoom (vertical scroll / drag).
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
            // Bottom ruler → horizontal zoom (horizontal scroll / drag): drag
            // left expands the chart, drag right compresses it.
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
      },
    );
  }

  void _setCursor(Offset? pos) {
    if (pos == _cursor) return;
    setState(() => _cursor = pos);
  }

  /// Positive [dy] (moving/scrolling down) compresses; negative expands.
  void _zoomY(double dy) {
    final next = (_yZoom * math.exp(-dy * 0.01)).clamp(_minYZoom, _maxYZoom);
    if (next == _yZoom) return;
    setState(() => _yZoom = next);
  }

  /// Positive [delta] (dragging right / scrolling down) compresses the chart by
  /// widening the visible window; negative (dragging left) expands it. Can widen
  /// past the data (empty space fills the left) or zoom into the newest slice.
  void _zoomX(double delta, double fullSpan) {
    final current = _xSpanMs ?? fullSpan;
    final next = (current * math.exp(delta * 0.01))
        .clamp(fullSpan / _maxXZoom, fullSpan * _maxXOut);
    if (next == _xSpanMs) return;
    setState(() => _xSpanMs = next);
  }

  /// Decimal-safe parse → percent as double (for pixels only).
  static double? _pct(String? fraction) {
    final value = Decimals.parse(fraction);
    return value == null ? null : value.toDouble() * 100;
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
/// (positive = compress) and a double-tap into a reset. Used for both rulers.
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
          onVerticalDragUpdate:
              horizontal ? null : (e) => onZoom(e.delta.dy),
          onHorizontalDragUpdate:
              horizontal ? (e) => onZoom(e.delta.dx) : null,
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
  final List<Offset> inSpots;
  final List<Offset> outSpots;
  final Set<double> cappedX;
  final _ChartGeometry geom;
  final Offset? cursor;

  _ChartPainter({
    required this.inSpots,
    required this.outSpots,
    required this.cappedX,
    required this.geom,
    required this.cursor,
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
    _drawTimeAxis(canvas, plot);

    // Series are clipped to the plot so zoomed-out overshoot stays hidden.
    canvas.save();
    canvas.clipRect(plot);
    _drawSeries(canvas, plot, outSpots, _outColor, width: 1.2, dashed: true);
    _drawSeries(canvas, plot, inSpots, _inColor, width: 1.6);
    _drawCappedDots(canvas, plot);
    canvas.restore();

    _drawLatestTags(canvas, plot);
    _drawCrosshair(canvas, plot);
  }

  // --- coordinate mapping -------------------------------------------------

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

  double _pxToY(Rect plot, double px) =>
      geom.maxY - (px - plot.top) / plot.height * (geom.maxY - geom.minY);

  double _pxToX(Rect plot, double px) =>
      geom.minX + (px - plot.left) / plot.width * (geom.maxX - geom.minX);

  // --- pieces -------------------------------------------------------------

  void _drawGridAndValueAxis(Canvas canvas, Rect plot) {
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    // The 0 line (perfect price match) is drawn brighter as the reference.
    final zeroPaint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1;
    // Ticks from 0 outward so 0 always lands on a line.
    final first = (geom.minY / geom.interval).ceil();
    final last = (geom.maxY / geom.interval).floor();
    for (var i = first; i <= last; i++) {
      final value = i * geom.interval;
      final y = _yToPx(plot, value);
      final isZero = value.abs() < geom.interval / 1000;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y),
          isZero ? zeroPaint : gridPaint);
      _text(
        canvas,
        _fmtPct(value, geom.interval),
        Offset(plot.right + 6, y),
        color: _axisText,
        align: TextAlign.left,
        anchorY: _AnchorY.center,
      );
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

  void _drawSeries(
    Canvas canvas,
    Rect plot,
    List<Offset> spots,
    Color color, {
    required double width,
    bool dashed = false,
  }) {
    if (spots.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Only segments that touch the visible x-window matter.
    Offset? prev;
    for (final s in spots) {
      final p = Offset(_xToPx(plot, s.dx), _yToPx(plot, s.dy));
      if (prev != null) {
        if (dashed) {
          _dashedSegment(canvas, prev, p, paint);
        } else {
          canvas.drawLine(prev, p, paint);
        }
      }
      prev = p;
    }
  }

  void _drawCappedDots(Canvas canvas, Rect plot) {
    if (cappedX.isEmpty) return;
    final paint = Paint()..color = _outColor.withValues(alpha: 0.85);
    for (final s in inSpots) {
      if (!cappedX.contains(s.dx)) continue;
      canvas.drawCircle(
        Offset(_xToPx(plot, s.dx), _yToPx(plot, s.dy)),
        1.8,
        paint,
      );
    }
  }

  /// Dotted reference lines + right-edge colored tags at the newest In/Out.
  void _drawLatestTags(Canvas canvas, Rect plot) {
    _latestTag(canvas, plot, inSpots.last.dy, _inColor);
    if (outSpots.length >= 2) {
      _latestTag(canvas, plot, outSpots.last.dy, _outColor);
    }
  }

  void _latestTag(Canvas canvas, Rect plot, double value, Color color) {
    final y = _yToPx(plot, value).clamp(plot.top, plot.bottom);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    _dashedSegment(canvas, Offset(plot.left, y), Offset(plot.right, y), paint);
    _tag(canvas, plot.right, y, value.toStringAsFixed(2), color);
  }

  void _drawCrosshair(Canvas canvas, Rect plot) {
    final c = cursor;
    if (c == null || !plot.contains(c)) return;

    final paint = Paint()
      ..color = _crosshair
      ..strokeWidth = 1;
    _dashedSegment(canvas, Offset(plot.left, c.dy), Offset(plot.right, c.dy),
        paint, dash: 4, gap: 4);
    _dashedSegment(canvas, Offset(c.dx, plot.top), Offset(c.dx, plot.bottom),
        paint, dash: 4, gap: 4);

    // Axis tags at the cursor.
    final value = _pxToY(plot, c.dy);
    _tag(canvas, plot.right, c.dy, _fmtPct(value, geom.interval), _axisText,
        bg: const Color(0xFF2A2E39), fg: Colors.white);
    final ts = _pxToX(plot, c.dx).toInt();
    _timeTag(canvas, c.dx, plot.bottom, _hms(ts));

    // Value box near the cursor: In/Out at the nearest sample.
    final nearest = _nearestByX(inSpots, _pxToX(plot, c.dx));
    if (nearest != null) {
      final inV = nearest.dy;
      final outV = _nearestByX(outSpots, nearest.dx)?.dy;
      final lines = <(String, Color)>[
        ('In  ${inV.toStringAsFixed(3)}%', _inColor),
        if (outV != null) ('Out ${outV.toStringAsFixed(3)}%', _outColor),
      ];
      _tooltip(canvas, plot, c, lines);
    }
  }

  // --- primitives ---------------------------------------------------------

  void _tag(Canvas canvas, double rightEdge, double cy, String text, Color color,
      {Color? bg, Color? fg}) {
    final tp = _layout(text, fg ?? _tagText, 10, FontWeight.w600);
    const padH = 5.0;
    const padV = 2.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;
    final top = (cy - h / 2).clamp(0.0, double.infinity);
    final rect = Rect.fromLTWH(rightEdge + 2, top, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = bg ?? color,
    );
    tp.paint(canvas, Offset(rect.left + padH, rect.top + padV));
  }

  void _timeTag(Canvas canvas, double cx, double axisTop, String text) {
    final tp = _layout(text, Colors.white, 10, FontWeight.w500);
    const padH = 5.0;
    const padV = 2.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;
    final left = (cx - w / 2);
    final rect = Rect.fromLTWH(left, axisTop + 2, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF2A2E39),
    );
    tp.paint(canvas, Offset(rect.left + padH, rect.top + padV));
  }

  void _tooltip(Canvas canvas, Rect plot, Offset c, List<(String, Color)> lines) {
    final painters = [
      for (final (t, col) in lines) _layout(t, col, 11, FontWeight.w500),
    ];
    final w = painters.map((p) => p.width).reduce(math.max) + 16;
    final h = painters.fold(0.0, (a, p) => a + p.height) + 12;
    // Flip to the left of the cursor if it would overflow the right edge.
    var left = c.dx + 12;
    if (left + w > plot.right) left = c.dx - 12 - w;
    var top = c.dy + 12;
    if (top + h > plot.bottom) top = plot.bottom - h;
    final rect = Rect.fromLTWH(left, top, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xE61C1F26),
    );
    var y = rect.top + 6;
    for (final p in painters) {
      p.paint(canvas, Offset(rect.left + 8, y));
      y += p.height;
    }
  }

  void _dashedSegment(Canvas canvas, Offset from, Offset to, Paint paint,
      {double dash = 3, double gap = 3}) {
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

  static Offset? _nearestByX(List<Offset> spots, double x) {
    if (spots.isEmpty) return null;
    Offset best = spots.first;
    var bestD = (best.dx - x).abs();
    for (final s in spots) {
      final d = (s.dx - x).abs();
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best;
  }

  void _text(Canvas canvas, String text, Offset at,
      {required Color color,
      TextAlign align = TextAlign.left,
      _AnchorY anchorY = _AnchorY.top}) {
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
    return '${shown.toStringAsFixed(decimals)}%';
  }

  static String _hms(int tsMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(tsMs);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.inSpots != inSpots ||
      old.outSpots != outSpots ||
      old.cursor != cursor ||
      old.geom.minX != geom.minX ||
      old.geom.maxX != geom.maxX ||
      old.geom.minY != geom.minY ||
      old.geom.maxY != geom.maxY;
}

enum _AnchorY { top, center }
