import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../core/grid/grid_cell.dart';

/// Animated edition overlays drawn across the WHOLE cell: a drifting prismatic
/// glow plus a diagonal shine band. Purely canvas gradients driven by [time],
/// so it needs no shader assets and runs the same on Android and iOS.
abstract final class EditionShimmerPainter {
  static const _holo = [
    Color(0xFF00E5FF),
    Color(0xFFFF2FD0),
    Color(0xFF00E5FF),
  ];
  static const _rainbow = [
    Color(0xFFFF5252),
    Color(0xFFFFD740),
    Color(0xFF69F0AE),
    Color(0xFF40C4FF),
    Color(0xFFE040FB),
    Color(0xFFFF5252),
  ];

  /// Cells at different board positions sweep at slightly different moments,
  /// so the shine reads as one band crossing the board.
  static double _offset(Rect rect) => (rect.left + rect.top) * 0.006;

  static void paint(Canvas canvas, Rect rect, CellEdition edition, double t) {
    switch (edition) {
      case CellEdition.none:
        return;
      case CellEdition.holo:
        // Tint first so cyan and magenta show over the blue block, then
        // screen a second pass on top for the glow.
        _glow(canvas, rect, _holo, TileMode.mirror, t * 0.55, 0.5, true);
        _glow(canvas, rect, _holo, TileMode.mirror, t * 0.55, 0.3);
        _shine(canvas, rect, t * 0.5 + _offset(rect), 0.75);
      case CellEdition.polychrome:
        _glow(canvas, rect, _rainbow, TileMode.repeated, t * 0.4, 0.55, true);
        _glow(canvas, rect, _rainbow, TileMode.repeated, t * 0.4, 0.35);
        _shine(canvas, rect, t * 0.45 + _offset(rect), 0.7);
      case CellEdition.foil:
        _silver(canvas, rect, t);
        _shine(canvas, rect, t * 0.6 + _offset(rect), 0.95);
    }
  }

  /// A colour ramp sliding diagonally across the square. `screen` blending
  /// makes it glow instead of covering the cell's own colour.
  static void _glow(
    Canvas canvas,
    Rect rect,
    List<Color> colors,
    TileMode mode,
    double phase,
    double alpha, [
    bool tint = false,
  ]) {
    final shift = (phase % 1) * rect.width * 2;
    final from = rect.topLeft + Offset(shift, shift * 0.6);
    final to = from + Offset(rect.width * 1.3, rect.height * 0.8);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = tint ? BlendMode.srcOver : BlendMode.screen
        ..shader = ui.Gradient.linear(
          from,
          to,
          [for (final c in colors) c.withValues(alpha: alpha)],
          // Explicit, evenly spaced stops: Gradient.linear rejects more than
          // two colours without them.
          [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
          mode,
        ),
    );
  }

  /// A soft white diagonal band that travels left to right, then rests for a
  /// moment before the next sweep.
  static void _shine(Canvas canvas, Rect rect, double phase, double alpha) {
    final p = (phase % 1.6) / 1.0; // 0..1.6: values above 1 = resting
    if (p > 1) return;
    final w = rect.width;
    final x = rect.left - w * 0.6 + p * w * 2.2;
    final skew = w * 0.45;
    final band = Path()
      ..moveTo(x, rect.bottom)
      ..lineTo(x + skew, rect.top)
      ..lineTo(x + skew + w * 0.3, rect.top)
      ..lineTo(x + w * 0.3, rect.bottom)
      ..close();
    final ease = sin(p * pi); // fade in and out at the edges
    canvas.drawPath(
      band,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(
          Offset(x, rect.center.dy),
          Offset(x + w * 0.3 + skew, rect.center.dy),
          [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, alpha * ease),
            const Color(0x00FFFFFF),
          ],
          const [0, 0.5, 1],
        ),
    );
  }

  /// Foil: a brushed-silver wash with a frame, so it reads as metallic foil
  /// even between shine sweeps.
  static void _silver(Canvas canvas, Rect rect, double t) {
    final drift = 0.15 * sin(t * 1.4);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment(-1 + drift, -1),
          end: Alignment(1 + drift, 1),
          colors: const [
            Color(0x99F5F5F5),
            Color(0x55B0BEC5),
            Color(0x99FFFFFF),
            Color(0x55B0BEC5),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xCCECEFF1),
    );
  }
}
