import 'dart:math';

import 'package:flutter/material.dart';

import '../core/grid/grid_cell.dart';
import '../core/polyomino/block_color.dart';
import '../core/roguelite/starter_decks.dart';
import '../game/cell_visual_renderer.dart';

/// A painted icon for a starter deck, drawn with the real block renderer so
/// the blocks look exactly like the ones in play.
class DeckEmblem extends StatelessWidget {
  const DeckEmblem({super.key, required this.deckId, this.size = 120});

  final String deckId;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _EmblemPainter(deckId));
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.deckId);

  final String deckId;

  static void _block(Canvas c, Rect r, BlockColor color) =>
      CellVisualRenderer.paint(c, r.deflate(1), GridCell(color: color), 0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    switch (deckId) {
      case 'deck_monolith_cube':
        // One big solid 3x3 cube.
        final cell = s / 3.4;
        final origin = Offset((s - cell * 3) / 2, (s - cell * 3) / 2);
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 3; c++) {
            _block(
              canvas,
              Rect.fromLTWH(
                origin.dx + c * cell,
                origin.dy + r * cell,
                cell,
                cell,
              ),
              BlockColor.blue,
            );
          }
        }
      case 'deck_crimson_recycler':
        _recycle(canvas, s);
      case 'deck_azure_architect':
        // Six little trays: the extra tray each blind.
        final w = s * 0.42, h = s * 0.2;
        for (var i = 0; i < 6; i++) {
          final rect = Rect.fromLTWH(
            s * 0.06 + (i % 2) * (w + s * 0.04),
            s * 0.12 + (i ~/ 2) * (h + s * 0.08),
            w,
            h,
          );
          final tray = RRect.fromRectAndRadius(rect, const Radius.circular(6));
          canvas.drawRRect(tray, Paint()..color = const Color(0xFF1E3A5F));
          canvas.drawRRect(
            tray,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF38BDF8),
          );
          _block(
            canvas,
            Rect.fromLTWH(rect.left + 6, rect.top + 4, h - 8, h - 8),
            BlockColor.blue,
          );
        }
      case 'deck_chromatic_flush':
        // A red and blue checkerboard.
        final cell = s / 4.4;
        final origin = Offset((s - cell * 4) / 2, (s - cell * 4) / 2);
        for (var r = 0; r < 4; r++) {
          for (var c = 0; c < 4; c++) {
            _block(
              canvas,
              Rect.fromLTWH(
                origin.dx + c * cell,
                origin.dy + r * cell,
                cell,
                cell,
              ),
              (r + c).isEven ? BlockColor.red : BlockColor.blue,
            );
          }
        }
      default:
        // Standard: one block of each of the four colors.
        final cell = s / 2.4;
        final origin = Offset((s - cell * 2) / 2, (s - cell * 2) / 2);
        const colors = [
          BlockColor.red,
          BlockColor.blue,
          BlockColor.green,
          BlockColor.yellow,
        ];
        for (var i = 0; i < 4; i++) {
          _block(
            canvas,
            Rect.fromLTWH(
              origin.dx + (i % 2) * cell,
              origin.dy + (i ~/ 2) * cell,
              cell,
              cell,
            ),
            colors[i],
          );
        }
    }
  }

  /// Two chasing red arrows: a recycling loop (a discard comes back).
  void _recycle(Canvas canvas, double s) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEF4444);
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: s * 0.32,
    );
    for (final start in [0.3, pi + 0.3]) {
      canvas.drawArc(rect, start, pi * 0.62, false, paint);
      final end = start + pi * 0.62;
      final tip = Offset(
        s / 2 + cos(end) * s * 0.32,
        s / 2 + sin(end) * s * 0.32,
      );
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx + cos(end - 2.5) * s * 0.16,
          tip.dy + sin(end - 2.5) * s * 0.16,
        )
        ..lineTo(
          tip.dx + cos(end + 0.55) * s * 0.16,
          tip.dy + sin(end + 0.55) * s * 0.16,
        )
        ..close();
      canvas.drawPath(head, Paint()..color = const Color(0xFFEF4444));
    }
    canvas.drawCircle(
      Offset(s / 2, s / 2),
      s * 0.07,
      Paint()..color = const Color(0xFFFF8A80),
    );
  }

  @override
  bool shouldRepaint(_EmblemPainter old) => old.deckId != deckId;
}

/// The theme color of each deck (its emblem glow and accents).
Color deckAccent(String deckId) => switch (deckId) {
  'deck_monolith_cube' => const Color(0xFF3B82F6),
  'deck_crimson_recycler' => const Color(0xFFEF4444),
  'deck_azure_architect' => const Color(0xFF38BDF8),
  'deck_chromatic_flush' => const Color(0xFFA855F7),
  _ => const Color(0xFF94A3B8),
};

/// Convenience for tests and screens.
Color accentOf(StarterDeck deck) => deckAccent(deck.id);
