import 'dart:math';

import 'package:flutter/painting.dart';

/// The full-square looks for the non-steel enhancements (Bonus gold, Mult,
/// Glass, Lucky) plus the small drawing helpers the renderer shares.
abstract final class EnhancementCellPainter {
  static Shader vertical(Rect r, List<Color> colors, [List<double>? stops]) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(r);

  static void frame(Canvas canvas, Rect r, Color color, double width) {
    canvas.drawRect(
      r.deflate(width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  /// A diagonal soft highlight band (used for gloss on several looks).
  static void _gloss(Canvas canvas, Rect r, double alpha) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, alpha),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.2, 0.38, 0.56],
        ).createShader(r),
    );
  }

  /// Bonus: rich metallic gold with a double frame.
  static void gold(Canvas canvas, Rect r) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = vertical(
          r,
          const [
            Color(0xFFFFE9A0),
            Color(0xFFFFC107),
            Color(0xFFE08A00),
            Color(0xFFFFCA28),
          ],
          const [0, 0.35, 0.75, 1],
        ),
    );
    _gloss(canvas, r, 0.55);
    frame(canvas, r, const Color(0xFF9A6A00), 2.4);
    frame(canvas, r.deflate(2.4), const Color(0xFFFFF3C4), 1.1);
  }

  /// Mult: crimson that breathes.
  static void mult(Canvas canvas, Rect r, double t) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = vertical(r, const [Color(0xFFEF5350), Color(0xFFA81414)]),
    );
    final pulse = 0.5 + 0.5 * sin(t * 3.4);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 138, 128, 0.20 + 0.35 * pulse),
            const Color(0x00FF8A80),
          ],
        ).createShader(r),
    );
    frame(canvas, r, Color.fromRGBO(255, 82, 82, 0.6 + 0.4 * pulse), 2);
  }

  /// Glass: translucent ice, so the empty tile shows through, with a frame
  /// and two diagonal reflections.
  static void glass(Canvas canvas, Rect r) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = vertical(r, const [Color(0x99E1F5FE), Color(0x6681D4FA)]),
    );
    final w = r.width;
    for (final (offset, width, alpha) in [
      (0.18, 0.16, 0.5),
      (0.5, 0.07, 0.35),
    ]) {
      final x = r.left + w * offset;
      canvas.drawPath(
        Path()
          ..moveTo(x, r.bottom)
          ..lineTo(x + w * 0.55, r.top)
          ..lineTo(x + w * (0.55 + width), r.top)
          ..lineTo(x + w * width, r.bottom)
          ..close(),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }
    frame(canvas, r, const Color(0xFFB3E5FC), 2.4);
    frame(canvas, r.deflate(2.4), const Color(0x66FFFFFF), 1);
  }

  /// Lucky: emerald with twinkling sparkles.
  static void lucky(Canvas canvas, Rect r, double t) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = vertical(r, const [Color(0xFF7BD17F), Color(0xFF2B7A31)]),
    );
    frame(canvas, r, const Color(0xFFA5D6A7), 1.8);
    const spots = [Offset(0.28, 0.3), Offset(0.7, 0.42), Offset(0.45, 0.72)];
    for (var i = 0; i < spots.length; i++) {
      final a = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 4 + i * 2.1));
      _sparkle(
        canvas,
        Offset(r.left + r.width * spots[i].dx, r.top + r.height * spots[i].dy),
        r.width * (0.1 + 0.03 * i),
        Color.fromRGBO(255, 255, 255, a),
      );
    }
  }

  static void _sparkle(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.28, c.dy - s * 0.28)
      ..lineTo(c.dx + s, c.dy)
      ..lineTo(c.dx + s * 0.28, c.dy + s * 0.28)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx - s * 0.28, c.dy + s * 0.28)
      ..lineTo(c.dx - s, c.dy)
      ..lineTo(c.dx - s * 0.28, c.dy - s * 0.28)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
