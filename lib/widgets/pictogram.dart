import 'package:material_ui/material_ui.dart';

import '../catalog.dart';
import '../theme.dart';

/// The purple tile with an exercise pictogram, or the first letter of [name]
/// when the exercise is not from the catalog.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.catalogId,
    required this.name,
    this.size = 48,
  });

  final String? catalogId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final entry = catalogEntry(catalogId);
    final radius = BorderRadius.circular(size * 14 / 64);
    if (entry == null) {
      final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Palette.purpleChip, borderRadius: radius),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            color: Palette.purpleChipText,
          ),
        ),
      );
    }
    return Semantics(
      label: entry.nameEn,
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: PosePainter(entry.pose),
      ),
    );
  }
}

/// Paints a [Pose] scaled from the 64 x 64 grid to the widget size.
class PosePainter extends CustomPainter {
  const PosePainter(this.pose);

  final Pose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 64;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(14 * scale),
      ),
      Paint()..color = Palette.purpleChip,
    );
    canvas.save();
    canvas.scale(scale);

    final gear = Paint()
      ..color = Palette.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = Paint()
      ..color = Palette.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final weight = Paint()
      ..color = Palette.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final line in pose.gear) {
      canvas.drawPath(_path(line), gear);
    }
    for (final pulley in pose.pulleys) {
      canvas.drawCircle(_offset(pulley.center), pulley.radius, gear);
    }
    for (final line in pose.body) {
      canvas.drawPath(_path(line), body);
    }
    canvas.drawCircle(_offset(pose.head), 5, Paint()..color = Palette.yellow);
    for (final plate in pose.plates) {
      canvas.drawCircle(_offset(plate.center), plate.radius, weight);
    }
    for (final bell in pose.dumbbells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: _offset(bell), width: 10, height: 5),
          const Radius.circular(2),
        ),
        Paint()..color = Palette.text,
      );
    }
    canvas.restore();
  }

  static Offset _offset(GridPoint point) => Offset(point.$1, point.$2);

  static Path _path(List<GridPoint> points) {
    final path = Path()..moveTo(points.first.$1, points.first.$2);
    for (final point in points.skip(1)) {
      path.lineTo(point.$1, point.$2);
    }
    return path;
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) => oldDelegate.pose != pose;
}
