import 'dart:math';

import 'package:flutter/painting.dart';

import '../core/grid/grid_cell.dart';
import 'block_palette.dart';
import 'edition_shimmer_painter.dart';
import 'enhancement_cell_painter.dart';
import 'steel_cell_painter.dart';

/// Paints one cell as a FULL square (no corner dots). Used by the board and
/// the tray so a cell looks identical wherever it is.
///
/// Layers, bottom to top: enhancement look, edition shimmer, seal frame.
/// [time] is seconds and drives the animations (pass 0 for a still frame).
abstract final class CellVisualRenderer {
  static void paint(Canvas canvas, Rect rect, GridCell cell, double time) {
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * 0.1),
    );
    canvas.save();
    canvas.clipRRect(shape);
    switch (cell.enhancement) {
      case CellEnhancement.none:
        _plain(canvas, rect, BlockPalette.of(cell.color));
      case CellEnhancement.bonus:
        EnhancementCellPainter.gold(canvas, rect);
      case CellEnhancement.mult:
        EnhancementCellPainter.mult(canvas, rect, time);
      case CellEnhancement.glass:
        EnhancementCellPainter.glass(canvas, rect);
      case CellEnhancement.lucky:
        EnhancementCellPainter.lucky(canvas, rect, time);
      case CellEnhancement.steel:
        SteelCellPainter.paint(canvas, rect);
    }
    EditionShimmerPainter.paint(canvas, rect, cell.edition, time);
    if (cell.seal == CellSeal.red) _redSeal(canvas, rect, time);
    // An enhanced cell keeps its look; its color shows as a slim bottom edge.
    if (cell.enhancement != CellEnhancement.none && cell.color != null) {
      _colorEdge(canvas, rect, BlockPalette.of(cell.color));
    }
    canvas.restore();
  }

  static void _plain(Canvas canvas, Rect r, BlockShade shade) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = EnhancementCellPainter.vertical(r, [
          shade.light,
          shade.dark,
        ]),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.2),
      Paint()..color = const Color(0x2EFFFFFF),
    );
    EnhancementCellPainter.frame(canvas, r, shade.frame, 1.2);
  }

  static void _colorEdge(Canvas canvas, Rect r, BlockShade shade) {
    canvas.drawRect(
      Rect.fromLTWH(
        r.left,
        r.bottom - r.height * 0.13,
        r.width,
        r.height * 0.13,
      ),
      Paint()..color = shade.dark,
    );
  }

  /// Red Seal: a pulsing red frame with an inner glow, around the whole cell.
  static void _redSeal(Canvas canvas, Rect r, double t) {
    final pulse = 0.5 + 0.5 * sin(t * 3 + 1);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: 0.85,
          colors: [
            const Color(0x00FF1744),
            Color.fromRGBO(255, 23, 68, 0.28 + 0.2 * pulse),
          ],
          stops: const [0.55, 1],
        ).createShader(r),
    );
    EnhancementCellPainter.frame(
      canvas,
      r,
      Color.fromRGBO(255, 23, 68, 0.75 + 0.25 * pulse),
      2.6,
    );
  }
}
