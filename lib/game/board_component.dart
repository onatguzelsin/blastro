import 'dart:ui';

import 'package:flame/components.dart';

import '../core/grid/grid_matrix.dart';
import '../core/roguelite/boss_blinds.dart';
import 'cell_visual_renderer.dart';
import 'game_layout.dart';

/// Draws the 8x8 grid and its occupied cells.
class BoardComponent extends PositionComponent {
  BoardComponent(this.layout, GridMatrix grid)
    : _grid = grid,
      super(position: layout.boardOrigin, size: Vector2.all(layout.boardSide));

  final GameLayout layout;
  GridMatrix _grid;

  static final _emptyPaint = Paint()..color = const Color(0xFF1E2433);
  static final _framePaint = Paint()..color = const Color(0xFF2B3347);

  set grid(GridMatrix value) => _grid = value;

  /// The active Boss Blind; cells it switches off get a red cross.
  BossBlind? boss;

  /// Animation clock in seconds (set by the game every frame). Drives the
  /// shimmer, pulse and twinkle of special cells.
  double time = 0;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().inflate(4),
        const Radius.circular(10),
      ),
      _framePaint,
    );
    final c = layout.cell;
    for (var r = 0; r < GridMatrix.size; r++) {
      for (var col = 0; col < GridMatrix.size; col++) {
        final rect = Rect.fromLTWH(col * c + 1, r * c + 1, c - 2, c - 2);
        // The empty tile is always drawn first so translucent cells (Glass)
        // show it through.
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          _emptyPaint,
        );
        final cell = _grid.at(r, col);
        if (cell == null) continue;
        CellVisualRenderer.paint(canvas, rect, cell, time);
        if (boss?.debuffsCell(cell) ?? false) _drawDebuffCross(canvas, rect);
      }
    }
  }

  static final _dimPaint = Paint()..color = const Color(0x99000000);
  static final _crossPaint = Paint()
    ..color = const Color(0xFFFF1744)
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  /// Dims a debuffed cell and strikes it with a bold red X.
  void _drawDebuffCross(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      _dimPaint,
    );
    final r = rect.deflate(rect.width * 0.2);
    canvas.drawLine(r.topLeft, r.bottomRight, _crossPaint);
    canvas.drawLine(r.topRight, r.bottomLeft, _crossPaint);
  }
}
