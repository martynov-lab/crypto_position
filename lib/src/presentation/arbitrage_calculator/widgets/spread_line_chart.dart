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
///
/// The plot can be panned: drag with the **left mouse button** on desktop, or
/// **double-tap and drag** on touch. Panning is clamped so the data can never
/// leave the visible area; double-tapping a ruler also resets that axis' pan.
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
const _crosshair = Color(0xB3FFFFFF);

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

  /// Raw cursor position (widget pixels) for the crosshair, or null when away.
  Offset? _cursor;

  /// Pan offsets in value units: how far the view is shifted into the past (ms)
  /// and off the 0-centre (percent). Both are clamped each frame so the data
  /// can never leave the visible area.
  double _xOffsetMs = 0;
  double _yOffsetPct = 0;

  /// True while a right-button (desktop) or double-tap (touch) drag is panning.
  bool _panning = false;
  Offset _lastPanPos = Offset.zero;

  /// Last pointer-down time/place, for double-tap-drag detection on touch.
  int _lastDownMs = 0;
  Offset _lastDownPos = Offset.zero;

  // Per-frame px→value factors and pan clamps, cached for the drag handlers.
  double _msPerPx = 0;
  double _pctPerPx = 0;
  double _panXMin = 0;
  double _panXMax = 0;
  double _panYAbs = 0;

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
    // Vertical pan shifts the centre off 0, clamped so the view centre stays
    // within the data's extremes — the line can never leave the plot.
    _yOffsetPct = _yOffsetPct.clamp(-maxAbs, maxAbs);
    final minY = _yOffsetPct - half;
    final maxY = _yOffsetPct + half;
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
    // Horizontal pan slides the window between "left edge at the oldest sample"
    // and "right edge at the newest" (the bounds swap when the window is wider
    // than the data), so some data is always on-screen.
    _panXMin = math.min(0.0, fullSpan - span);
    _panXMax = math.max(0.0, fullSpan - span);
    _xOffsetMs = _xOffsetMs.clamp(_panXMin, _panXMax);
    _panYAbs = maxAbs;
    final maxX = lastX - _xOffsetMs;
    final geom = _ChartGeometry(
      minX: maxX - span,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      interval: interval,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // px→value factors for the pan drag handlers.
        _msPerPx =
            span / math.max(constraints.maxWidth - _leftPad - _rightAxis, 1);
        _pctPerPx = (maxY - minY) /
            math.max(constraints.maxHeight - _topPad - _bottomAxis, 1);

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ChartPainter(
                spots: spots,
                geom: geom,
                buyLabel: widget.buyLabel,
                sellLabel: widget.sellLabel,
                cursor: _cursor,
              ),
            ),
            // Crosshair + pan layer: whole area; the ruler strips below sit on
            // top and claim their own gestures, so this only acts on the plot.
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: (_) => _panning = false,
              onPointerCancel: (_) => _panning = false,
              child: MouseRegion(
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
                onReset: () => setState(() {
                  _yZoom = 1;
                  _yOffsetPct = 0;
                }),
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
                onReset: () => setState(() {
                  _xSpanMs = null;
                  _xOffsetMs = 0;
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Starts a pan on a left-button press (desktop mouse) or a second tap
  /// landing within 300 ms / 40 px of the previous one (touch double-tap-drag).
  void _handlePointerDown(PointerDownEvent e) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Touch also reports kPrimaryButton, so the mouse check needs the kind too.
    final isPrimaryMouse = e.kind == PointerDeviceKind.mouse &&
        (e.buttons & kPrimaryMouseButton) != 0;
    final isDoubleTap = e.kind == PointerDeviceKind.touch &&
        now - _lastDownMs < 300 &&
        (e.localPosition - _lastDownPos).distance < 40;
    _lastDownMs = now;
    _lastDownPos = e.localPosition;
    if (isPrimaryMouse || isDoubleTap) {
      _panning = true;
      _lastPanPos = e.localPosition;
      _setCursor(null);
    }
  }

  /// Moves the view with the pointer: content follows the drag, clamped so the
  /// data always stays on-screen.
  void _handlePointerMove(PointerMoveEvent e) {
    if (!_panning) return;
    final delta = e.localPosition - _lastPanPos;
    _lastPanPos = e.localPosition;
    setState(() {
      _xOffsetMs =
          (_xOffsetMs + delta.dx * _msPerPx).clamp(_panXMin, _panXMax);
      _yOffsetPct =
          (_yOffsetPct + delta.dy * _pctPerPx).clamp(-_panYAbs, _panYAbs);
    });
  }

  void _setCursor(Offset? pos) {
    // While panning, the touch drag also reaches the crosshair gestures —
    // suppress it so the crosshair doesn't chase the panning finger.
    if (_panning && pos != null) return;
    if (pos == _cursor) return;
    setState(() => _cursor = pos);
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
  final Offset? cursor;

  _ChartPainter({
    required this.spots,
    required this.geom,
    required this.buyLabel,
    required this.sellLabel,
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
    _drawReferenceLines(canvas, plot);
    _drawTimeAxis(canvas, plot);

    canvas.save();
    canvas.clipRect(plot);
    _drawAreaAndLine(canvas, plot);
    canvas.restore();

    _drawLegend(canvas, plot);
    // Painted last so it sits above the axis label it overlaps.
    _drawCurrentValueTag(canvas, plot, size);
    _drawCrosshair(canvas, plot);
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

  double _pxToY(Rect plot, double px) =>
      geom.maxY - (px - plot.top) / plot.height * (geom.maxY - geom.minY);

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

    // Gradient fill from the line down to the plot bottom. Opacity is tied to
    // the spread value itself (not the window position): transparent at 0%,
    // ramping linearly to 90% at 1% and constant above — so the fill reads the
    // same at any zoom/pan.
    final fill = Path()..moveTo(pixels.first.dx, plot.bottom);
    for (final p in pixels) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(pixels.last.dx, plot.bottom)
      ..close();

    // Vertical gradient with stops pinned to the 0% / 1% spread levels.
    double alphaFor(double v) => v <= 0
        ? 0.0
        : v >= 1.0
        ? 0.9
        : 0.9 * v;
    final stops = <double>[0];
    final colors = <Color>[_lineColor.withValues(alpha: alphaFor(geom.maxY))];
    for (final v in const [1.0, 0.0]) {
      final t = (geom.maxY - v) / (geom.maxY - geom.minY);
      if (t > 0 && t < 1) {
        stops.add(t);
        colors.add(_lineColor.withValues(alpha: alphaFor(v)));
      }
    }
    stops.add(1);
    colors.add(_lineColor.withValues(alpha: alphaFor(geom.minY)));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
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

  /// Rounded tag on the value ruler marking the latest spread, level with where
  /// the line ends. Filled with the line colour so it reads as that series'
  /// current value rather than another axis label.
  void _drawCurrentValueTag(Canvas canvas, Rect plot, Size size) {
    if (spots.isEmpty) return;
    final value = spots.last.dy;
    // Clamped so the tag stays visible when the last point is off-screen after
    // a vertical zoom.
    final y = _yToPx(plot, value).clamp(plot.top, plot.bottom);

    final decimals = geom.interval >= 0.1 ? 2 : 3;
    final tp = _layout(value.toStringAsFixed(decimals), _bg, 10, FontWeight.w700);

    const padX = 4.0;
    const padY = 2.0;
    final rect = Rect.fromLTWH(
      // Right-aligned to the canvas edge so a wide value can't overflow.
      size.width - 2 - (tp.width + padX * 2),
      y - (tp.height + padY * 2) / 2,
      tp.width + padX * 2,
      tp.height + padY * 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = _lineColor,
    );
    tp.paint(canvas, Offset(rect.left + padX, rect.top + padY));
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

  /// TradingView-style crosshair: dotted lines through the cursor, value/time
  /// tags on the rulers and a tooltip with the spread at the nearest sample.
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
    _tag(canvas, plot.right, c.dy, _fmtPct(value, geom.interval));
    final ts = _pxToX(plot, c.dx).toInt();
    _timeTag(canvas, c.dx, plot.bottom, _hms(ts));

    // Value box near the cursor: spread at the nearest sample.
    final nearest = _nearestByX(spots, _pxToX(plot, c.dx));
    if (nearest != null) {
      _tooltip(canvas, plot, c, [
        ('Спред ${nearest.dy.toStringAsFixed(3)}%', _lineColor),
      ]);
    }
  }

  // --- primitives -----------------------------------------------------------

  /// Grey value tag on the right ruler at [cy].
  void _tag(Canvas canvas, double rightEdge, double cy, String text) {
    final tp = _layout(text, Colors.white, 10, FontWeight.w600);
    const padH = 5.0;
    const padV = 2.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;
    final top = (cy - h / 2).clamp(0.0, double.infinity);
    final rect = Rect.fromLTWH(rightEdge + 2, top, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF2A2E39),
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
      old.cursor != cursor ||
      old.geom.minX != geom.minX ||
      old.geom.maxX != geom.maxX ||
      old.geom.minY != geom.minY ||
      old.geom.maxY != geom.maxY;
}

enum _AnchorY { top, center }
