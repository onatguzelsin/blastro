import 'package:flutter/painting.dart';

/// A full-square brushed-steel cell: metallic gradient, brushed grain, a
/// bevelled silver border, a diagonal sheen and four corner rivets.
abstract final class SteelCellPainter {
  static const Color _light = Color(0xFFECEFF1);
  static const Color _dark = Color(0xFF37474F);

  /// Paints into [rect]. Expects the caller to have clipped to the cell's
  /// rounded shape.
  static void paint(Canvas canvas, Rect rect) {
    _body(canvas, rect);
    _brushedGrain(canvas, rect);
    _sheen(canvas, rect);
    _bevel(canvas, rect);
    _rivets(canvas, rect);
  }

  static void _body(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCFD8DC),
            Color(0xFF90A4AE),
            Color(0xFF607D8B),
            Color(0xFF78909C),
          ],
          stops: [0, 0.38, 0.72, 1],
        ).createShader(rect),
    );
  }

  /// Fine horizontal scratches of varying strength, like brushed metal.
  static void _brushedGrain(Canvas canvas, Rect rect) {
    final paint = Paint()..strokeWidth = 1;
    var i = 0;
    for (var y = rect.top + 2; y < rect.bottom - 1; y += 2.4) {
      final strength = ((i * 37) % 7) / 7;
      paint.color =
          (i.isEven ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
              .withValues(alpha: 0.04 + 0.09 * strength);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      i++;
    }
  }

  static void _sheen(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: 0),
            const Color(0xFFFFFFFF).withValues(alpha: 0.42),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
          stops: const [0.22, 0.4, 0.58],
        ).createShader(rect),
    );
  }

  /// Light on the top and left edges, dark on the bottom and right, then a
  /// thin silver outline.
  static void _bevel(Canvas canvas, Rect rect) {
    final w = rect.width * 0.07;
    final lightPaint = Paint()
      ..color = _light.withValues(alpha: 0.95)
      ..strokeWidth = w;
    final darkPaint = Paint()
      ..color = _dark.withValues(alpha: 0.85)
      ..strokeWidth = w;
    final h = w / 2;
    canvas.drawLine(
      Offset(rect.left, rect.top + h),
      Offset(rect.right, rect.top + h),
      lightPaint,
    );
    canvas.drawLine(
      Offset(rect.left + h, rect.top),
      Offset(rect.left + h, rect.bottom),
      lightPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - h),
      Offset(rect.right, rect.bottom - h),
      darkPaint,
    );
    canvas.drawLine(
      Offset(rect.right - h, rect.top),
      Offset(rect.right - h, rect.bottom),
      darkPaint,
    );
    canvas.drawRect(
      rect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFCFD8DC),
    );
  }

  /// Four domed rivets, one per corner.
  static void _rivets(Canvas canvas, Rect rect) {
    final inset = rect.width * 0.2;
    final r = rect.width * 0.075;
    for (final c in [
      Offset(rect.left + inset, rect.top + inset),
      Offset(rect.right - inset, rect.top + inset),
      Offset(rect.left + inset, rect.bottom - inset),
      Offset(rect.right - inset, rect.bottom - inset),
    ]) {
      canvas.drawCircle(
        c + Offset(0, r * 0.35),
        r * 1.15,
        Paint()..color = _dark.withValues(alpha: 0.45),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.45),
            radius: 0.95,
            colors: [Color(0xFFFFFFFF), Color(0xFFB0BEC5), Color(0xFF546E7A)],
            stops: [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _dark.withValues(alpha: 0.7),
      );
    }
  }
}
