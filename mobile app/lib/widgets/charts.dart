import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Hand-rolled charts. Deliberately dependency-free so the build stays
/// reproducible and the styling matches the RESIVYN system exactly.

// ---------------------------------------------------------------------------
// Line chart
// ---------------------------------------------------------------------------

class RLineChart extends StatefulWidget {
  const RLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 160,
    this.color = RC.teal,
    this.valueFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;
  final String Function(double)? valueFormatter;

  @override
  State<RLineChart> createState() => _RLineChartState();
}

class _RLineChartState extends State<RLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  int? _touchedIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPosition, double width) {
    if (widget.values.length < 2) return;
    final step = width / (widget.values.length - 1);
    final index = (localPosition.dx / step).round().clamp(0, widget.values.length - 1);
    if (index != _touchedIndex) setState(() => _touchedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) => _handleTouch(d.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    _handleTouch(d.localPosition, constraints.maxWidth),
                onHorizontalDragEnd: (_) => setState(() => _touchedIndex = null),
                onTapUp: (_) => setState(() => _touchedIndex = null),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _LinePainter(
                      values: widget.values,
                      color: widget.color,
                      progress: Curves.easeOutCubic.transform(_controller.value),
                      touchedIndex: _touchedIndex,
                      tooltip: _touchedIndex == null
                          ? null
                          : (widget.valueFormatter?.call(
                                  widget.values[_touchedIndex!]) ??
                              widget.values[_touchedIndex!].toStringAsFixed(0)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: RS.x8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              Text(
                widget.labels[i],
                style: RT.captionSm.copyWith(
                  fontSize: 10,
                  color: i == _touchedIndex ? RC.navy : RC.textTertiary,
                  fontWeight:
                      i == _touchedIndex ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.progress,
    this.touchedIndex,
    this.tooltip,
  });

  final List<double> values;
  final Color color;
  final double progress;
  final int? touchedIndex;
  final String? tooltip;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    // Leave headroom so the peak never touches the top edge.
    const topPad = 18.0;
    const bottomPad = 8.0;
    final usableHeight = size.height - topPad - bottomPad;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = (values[i] - minV) / range;
      final y = topPad + usableHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    // Horizontal guide lines.
    final gridPaint = Paint()
      ..color = RC.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + usableHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Reveal animation clips the drawing horizontally.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = (p1.dx + p2.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    // Gradient fill under the curve.
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.26), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();

    // Data dots.
    for (var i = 0; i < points.length; i++) {
      if (points[i].dx > size.width * progress) continue;
      final isTouched = i == touchedIndex;
      canvas.drawCircle(points[i], isTouched ? 6 : 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        points[i],
        isTouched ? 6 : 4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isTouched ? 3 : 2.2,
      );
    }

    // Tooltip for the touched point.
    if (touchedIndex != null && tooltip != null) {
      final p = points[touchedIndex!];

      canvas.drawLine(
        Offset(p.dx, topPad),
        Offset(p.dx, size.height - bottomPad),
        Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = 1.5,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: tooltip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxWidth = tp.width + 16;
      final left = (p.dx - boxWidth / 2).clamp(0.0, size.width - boxWidth);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, boxWidth, tp.height + 10),
        const Radius.circular(7),
      );
      canvas.drawRRect(rect, Paint()..color = RC.navy);
      tp.paint(canvas, Offset(left + 8, 5));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress ||
      old.touchedIndex != touchedIndex ||
      old.values != values;
}

// ---------------------------------------------------------------------------
// Bar chart
// ---------------------------------------------------------------------------

class RBarChart extends StatefulWidget {
  const RBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 150,
    this.highlightLast = true,
    this.valueFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final bool highlightLast;
  final String Function(double)? valueFormatter;

  @override
  State<RBarChart> createState() => _RBarChartState();
}

class _RBarChartState extends State<RBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  int? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.highlightLast) _selected = widget.values.length - 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxV = widget.values.reduce(math.max);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.values.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: RS.x4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_selected == i && widget.valueFormatter != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: RS.x4),
                              child: Text(
                                widget.valueFormatter!(widget.values[i]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: RT.captionSm.copyWith(
                                  fontSize: 9.5,
                                  color: RC.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Flexible(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: double.infinity,
                              height: math.max(
                                4,
                                (widget.height - 42) *
                                    (widget.values[i] / maxV) *
                                    t,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _selected == i
                                      ? [RC.teal, RC.tealDark]
                                      : [
                                          RC.teal.withOpacity(0.22),
                                          RC.teal.withOpacity(0.12),
                                        ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                  bottom: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: RS.x8),
                          Text(
                            widget.labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RT.captionSm.copyWith(
                              fontSize: 10,
                              color: _selected == i ? RC.navy : RC.textTertiary,
                              fontWeight: _selected == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Donut chart
// ---------------------------------------------------------------------------

class RDonutChart extends StatefulWidget {
  const RDonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 150,
  });

  /// (value, colour) pairs.
  final List<(double, Color)> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  @override
  State<RDonutChart> createState() => _RDonutChartState();
}

class _RDonutChartState extends State<RDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _DonutPainter(
            segments: widget.segments,
            progress: Curves.easeOutCubic.transform(_controller.value),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.centerValue, style: RT.metric),
                const SizedBox(height: 2),
                Text(widget.centerLabel, style: RT.captionSm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.progress});

  final List<(double, Color)> segments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.$1);
    if (total <= 0) return;

    const stroke = 18.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    // Track.
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = RC.bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    var start = -math.pi / 2;
    const gap = 0.035;

    for (final (value, color) in segments) {
      final sweep = (value / total) * 2 * math.pi * progress;
      if (sweep <= gap) {
        start += sweep;
        continue;
      }
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}
