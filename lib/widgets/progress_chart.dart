import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../stats.dart';
import '../theme.dart';

/// Heaviest set per day as a line from 0 kg, purple fill below. Tap a point
/// to see its date and set; the latest point is selected by default.
class ProgressChart extends StatefulWidget {
  const ProgressChart({
    super.key,
    required this.points,
    required this.from,
    required this.to,
    this.height = 210,
  });

  /// Oldest first.
  final List<ChartPoint> points;

  /// Time range of the x axis.
  final DateTime from;
  final DateTime to;
  final double height;

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  int? _selected;

  @override
  void didUpdateWidget(ProgressChart old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Nothing logged in this range',
            style: TextStyle(color: Palette.muted),
          ),
        ),
      );
    }
    final selected = _selected ?? points.length - 1;
    return LayoutBuilder(
      builder: (context, box) {
        final geo = ChartGeometry(
          size: Size(box.maxWidth, widget.height),
          from: widget.from,
          to: widget.to,
          maxKg: points.map((point) => point.kg).reduce(math.max),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => setState(
            () => _selected = geo.nearest(points, details.localPosition.dx),
          ),
          onHorizontalDragUpdate: (details) => setState(
            () => _selected = geo.nearest(points, details.localPosition.dx),
          ),
          child: CustomPaint(
            size: Size(box.maxWidth, widget.height),
            painter: _ChartPainter(
              points: points,
              geo: geo,
              selected: selected,
            ),
          ),
        );
      },
    );
  }
}

/// Maps days and kg to pixels. The y axis always starts at 0 kg.
class ChartGeometry {
  ChartGeometry({
    required this.size,
    required this.from,
    required this.to,
    required double maxKg,
  }) {
    step = niceStep(maxKg);
    topKg = (maxKg / step).floor() * step + step;
  }

  final Size size;
  final DateTime from;
  final DateTime to;
  late final double step;
  late final double topKg;

  static const left = 34.0;
  static const right = 12.0;
  static const top = 34.0; // room for the tooltip
  static const bottom = 24.0; // room for month labels

  double get plotLeft => left;
  double get plotRight => size.width - right;
  double get plotTop => top;
  double get plotBottom => size.height - bottom;

  double x(DateTime day) {
    final span = to.difference(from).inMinutes;
    if (span <= 0) return (plotLeft + plotRight) / 2;
    final fraction = day.difference(from).inMinutes / span;
    return plotLeft + fraction.clamp(0.0, 1.0) * (plotRight - plotLeft);
  }

  double y(double kg) => plotBottom - kg / topKg * (plotBottom - plotTop);

  int nearest(List<ChartPoint> points, double dx) {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final distance = (x(points[i].day) - dx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  /// A round grid step giving about four lines up to [maxKg].
  static double niceStep(double maxKg) {
    if (maxKg <= 0) return 5;
    final raw = maxKg / 4;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    for (final multiplier in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (multiplier * magnitude >= raw) return multiplier * magnitude;
    }
    return 10 * magnitude;
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.geo,
    required this.selected,
  });

  final List<ChartPoint> points;
  final ChartGeometry geo;
  final int selected;

  static const _label = TextStyle(color: Palette.muted, fontSize: 11);

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas);
    _months(canvas);

    final offsets = [
      for (final point in points) Offset(geo.x(point.day), geo.y(point.kg)),
    ];

    // Fill under the line, fading to the 0 kg axis.
    if (offsets.length > 1) {
      final area = Path()..moveTo(offsets.first.dx, geo.plotBottom);
      for (final offset in offsets) {
        area.lineTo(offset.dx, offset.dy);
      }
      area
        ..lineTo(offsets.last.dx, geo.plotBottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.purple.withValues(alpha: 0.45),
                  Palette.purple.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromLTRB(
                  geo.plotLeft,
                  geo.plotTop,
                  geo.plotRight,
                  geo.plotBottom,
                ),
              ),
      );

      final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final offset in offsets.skip(1)) {
        line.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = Palette.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Points: hollow, the selected one solid and bigger.
    final ring = Paint()
      ..color = Palette.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final hole = Paint()..color = Palette.surface;
    for (var i = 0; i < offsets.length; i++) {
      if (i == selected) continue;
      canvas.drawCircle(offsets[i], 3.5, hole);
      canvas.drawCircle(offsets[i], 3.5, ring);
    }
    final sel = offsets[selected];
    canvas.drawLine(
      Offset(sel.dx, sel.dy),
      Offset(sel.dx, geo.plotBottom),
      Paint()
        ..color = Palette.yellow.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(sel, 6, Paint()..color = Palette.yellow);

    _tooltip(canvas, size, sel, points[selected]);
  }

  void _grid(Canvas canvas) {
    final paint = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (var kg = 0.0; kg <= geo.topKg + 0.001; kg += geo.step) {
      final y = geo.y(kg);
      canvas.drawLine(
        Offset(geo.plotLeft - 4, y),
        Offset(geo.plotRight, y),
        paint,
      );
      final label = _text(formatKg(kg), _label);
      label.paint(
        canvas,
        Offset(geo.plotLeft - 8 - label.width, y - label.height / 2),
      );
    }
  }

  void _months(Canvas canvas) {
    var month = DateTime(geo.from.year, geo.from.month + 1, 1);
    if (geo.from.day == 1) month = DateTime(geo.from.year, geo.from.month, 1);
    var lastX = -1000.0;
    var drawn = 0;
    while (!month.isAfter(geo.to)) {
      final x = geo.x(month);
      if (x - lastX >= 30) {
        final label = _text(monthShort(month.month), _label);
        label.paint(canvas, Offset(x - label.width / 2, geo.plotBottom + 6));
        lastX = x;
        drawn++;
      }
      month = DateTime(month.year, month.month + 1, 1);
    }
    if (drawn == 0) {
      // Range inside one month: name it at the left edge.
      final label = _text(monthShort(geo.from.month), _label);
      label.paint(canvas, Offset(geo.plotLeft, geo.plotBottom + 6));
    }
  }

  void _tooltip(Canvas canvas, Size size, Offset at, ChartPoint point) {
    final label = _text(
      '${formatDay(point.day)} - ${formatSet(point.top)}',
      const TextStyle(
        color: Palette.onYellow,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
    const padX = 8.0, padY = 5.0;
    final width = label.width + padX * 2, height = label.height + padY * 2;
    final left = (at.dx - width / 2).clamp(0.0, size.width - width);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 2, width, height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = Palette.yellow);
    label.paint(canvas, Offset(left + padX, 2 + padY));
  }

  static TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.geo.size != geo.size;
}
