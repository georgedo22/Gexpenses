import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The GExpenses app mark: a purple "G" swoosh with a growth arrow, a pie
/// chart and a bar chart.
///
/// Drawn with a [CustomPainter] (instead of a bitmap or an SVG package) so it
/// stays razor sharp at every size — from a 24 px avatar to a 1024 px store
/// icon. The exact same painter is rasterised by
/// `tool/generate_brand_assets.dart` to produce the launcher icons.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.showBackground = true});

  final double size;

  /// Paints the white rounded tile behind the mark (used for app icons).
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: BrandMarkPainter(showBackground: showBackground),
    );
  }
}

/// Paints the brand mark into a 512×512 logical box, scaled to [size].
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({this.showBackground = true, this.scale = 512});

  final bool showBackground;
  final double scale;

  static const Color _purpleDark = Color(0xFF5B21B6);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFC084FC);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    canvas.save();
    canvas.scale(s);

    if (showBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 512, 512),
          const Radius.circular(112),
        ),
        Paint()..color = Colors.white,
      );
    }

    final brandShader = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: const [_purpleDark, _purple, Color(0xFFA855F7)],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(60, 60, 400, 400));

    final arrowShader = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: const [_purple, _purpleLight],
    ).createShader(const Rect.fromLTWH(240, 150, 200, 220));

    // Thin decorative swoosh around the lower-left of the ring.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(252, 244), radius: 196),
      _rad(196),
      _rad(118),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = _purpleLight.withValues(alpha: 0.85),
    );

    // The "G": an almost full ring with the opening on the right side.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(252, 244), radius: 150),
      _rad(28),
      _rad(302),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 52
        ..strokeCap = StrokeCap.round
        ..shader = brandShader,
    );

    // Growth arrow leaving through the ring opening.
    canvas.drawLine(
      const Offset(288, 352),
      const Offset(406, 190),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..shader = arrowShader,
    );
    final head = Path()
      ..moveTo(430, 166)
      ..lineTo(366, 184)
      ..lineTo(414, 230)
      ..close();
    canvas.drawPath(head, Paint()..shader = arrowShader);

    // Pie chart.
    const pieCenter = Offset(196, 232);
    const pieRadius = 58.0;
    canvas.drawCircle(
      pieCenter,
      pieRadius,
      Paint()..color = const Color(0xFFF5F0FF),
    );
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieRadius),
      _rad(-88),
      _rad(118),
      true,
      Paint()..shader = brandShader,
    );
    final spoke = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pieCenter, pieCenter.translate(0, -pieRadius), spoke);
    canvas.drawLine(
      pieCenter,
      pieCenter.translate(
        pieRadius * math.cos(_rad(-88) + _rad(118)),
        pieRadius * math.sin(_rad(-88) + _rad(118)),
      ),
      spoke,
    );
    canvas.drawCircle(pieCenter, 7, Paint()..color = _purple);

    // Bar chart (bottom-left, clear of the arrow and the ring).
    _bar(canvas, const Rect.fromLTWH(146, 330, 28, 26), _purple);
    _bar(
      canvas,
      const Rect.fromLTWH(182, 312, 28, 44),
      const Color(0xFF8B5CF6),
    );
    _bar(
      canvas,
      const Rect.fromLTWH(218, 290, 28, 66),
      const Color(0xFFA855F7),
    );

    canvas.restore();
  }

  void _bar(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      Paint()..color = color,
    );
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant BrandMarkPainter oldDelegate) =>
      oldDelegate.showBackground != showBackground;
}
