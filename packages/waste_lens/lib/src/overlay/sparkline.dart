import 'package:flutter/widgets.dart';

/// A minimal, dependency-free line chart for a short numeric series.
///
/// Auto-scales to the series' own min/max so small RSS wiggles stay visible.
/// Renders nothing for fewer than two points (an empty/zero state).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.fillColor,
    this.strokeWidth = 1.5,
  });

  /// The series, oldest-to-newest.
  final List<double> values;

  /// Stroke colour for the line.
  final Color color;

  /// Optional translucent fill under the line.
  final Color? fillColor;

  /// Line thickness in logical pixels.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final Color? fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final range = (max - min).abs() < 1e-9 ? 1.0 : max - min;
    final dx = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final norm = (values[i] - min) / range;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = fillColor;
    if (fill != null) {
      final area = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(area, Paint()..color = fill);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth ||
      !_sameValues(old.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
