import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The trend line drawn under a stat card label.
///
/// It is a plain [CustomPaint]: no charting dependency, no interaction, no
/// axes. The point is peripheral vision — the shape of the last few periods —
/// not reading values off it.
///
/// This class is internal to the package and is not exported.
class StatSparkline extends StatelessWidget {
  /// Creates a sparkline for [points].
  const StatSparkline({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.height,
    super.key,
  });

  /// The series, oldest first. Non-finite entries are dropped.
  final List<double> points;

  /// Stroke colour, already resolved from the theme.
  final Color color;

  /// Stroke width in logical pixels.
  final double strokeWidth;

  /// The height the line is drawn into.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: SparklinePainter(
          points: points,
          color: color,
          strokeWidth: strokeWidth,
        ),
        // A sparkline restates the trend badge; announcing a list of numbers
        // to a screen reader would be noise.
        isComplex: false,
      ),
    );
  }
}

/// Paints a polyline normalised to the box it is given.
///
/// This class is internal to the package and is not exported.
class SparklinePainter extends CustomPainter {
  /// Creates a painter for [points].
  const SparklinePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  /// The series, oldest first.
  final List<double> points;

  /// Stroke colour.
  final Color color;

  /// Stroke width in logical pixels.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> values = points
        .where((double v) => v.isFinite)
        .toList(growable: false);
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final double lowest = values.reduce(math.min);
    final double highest = values.reduce(math.max);
    final double span = highest - lowest;

    // Half a stroke of padding top and bottom, so the extremes are not clipped
    // in half by the edge of the box.
    final double inset = strokeWidth / 2;
    final double usable = math.max(0, size.height - strokeWidth);
    final double step = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      // A flat series has no range to normalise against, so it is drawn down
      // the middle rather than divided by zero.
      final double t = span == 0 ? 0.5 : (values[i] - lowest) / span;
      final double x = i * step;
      final double y = inset + (1 - t) * usable;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        !listEquals(oldDelegate.points, points);
  }
}
