import 'dart:ui';

import 'package:flame/components.dart';

import '../core/grid/grid_cell.dart';
import '../core/grid/grid_matrix.dart';
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
  static final _cellPaint = Paint();
  static final _markPaint = Paint();

  set grid(GridMatrix value) => _grid = value;

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
        final cell = _grid.at(r, col);
        if (cell == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            _emptyPaint,
          );
        } else {
          _drawCell(canvas, rect, cell);
        }
      }
    }
  }

  void _drawCell(Canvas canvas, Rect rect, GridCell cell) {
    _cellPaint.color = _enhancementColor(cell.enhancement);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      _cellPaint,
    );
    if (cell.edition != CellEdition.none) {
      _markPaint.color = _editionColor(cell.edition);
      canvas.drawCircle(rect.topLeft + const Offset(7, 7), 3, _markPaint);
    }
    if (cell.seal == CellSeal.red) {
      _markPaint.color = const Color(0xFFFF1744);
      canvas.drawCircle(rect.bottomRight - const Offset(7, 7), 3, _markPaint);
    }
  }

  static Color _enhancementColor(CellEnhancement e) => switch (e) {
    CellEnhancement.none => const Color(0xFF5C8DFF),
    CellEnhancement.bonus => const Color(0xFF29B6F6),
    CellEnhancement.mult => const Color(0xFFEF5350),
    CellEnhancement.glass => const Color(0xFFB2EBF2),
    CellEnhancement.lucky => const Color(0xFF66BB6A),
    CellEnhancement.steel => const Color(0xFF90A4AE),
  };

  static Color _editionColor(CellEdition e) => switch (e) {
    CellEdition.foil => const Color(0xFFE0E0E0),
    CellEdition.holo => const Color(0xFFCE93D8),
    CellEdition.polychrome => const Color(0xFFFFEE58),
    CellEdition.none => const Color(0x00000000),
  };
}
