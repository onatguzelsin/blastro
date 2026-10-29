import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/grid/fit_validator.dart';
import '../core/grid/grid_matrix.dart';
import '../core/grid/line_detector.dart';
import '../core/polyomino/polyomino_shape.dart';
import 'game_layout.dart';

/// Ghost footprint of the piece being dragged plus pulsing highlights on
/// every row/column the drop would complete.
class BoardHighlight extends PositionComponent {
  BoardHighlight(this.layout)
    : super(
        position: layout.boardOrigin,
        size: Vector2.all(layout.boardSide),
        priority: 5,
      );

  final GameLayout layout;
  final List<CellOffset> _ghost = [];
  LineClears _lines = const LineClears();
  double _t = 0;

  static final _ghostPaint = Paint()..color = const Color(0x665CFFB0);
  static final _linePaint = Paint();

  /// Previews dropping [piece] with its top-left at ([row], [col]).
  /// Clears the preview if the placement is illegal.
  void preview(GridMatrix grid, Polyomino piece, int row, int col) {
    clear();
    if (!FitValidator.canPlace(grid, piece, row, col)) return;
    for (final o in piece.cells) {
      _ghost.add(CellOffset(row + o.row, col + o.col));
    }
    _lines = LineDetector.detect(grid.copy()..place(piece, row, col));
  }

  void clear() {
    _ghost.clear();
    _lines = const LineClears();
  }

  bool get hasGhost => _ghost.isNotEmpty;
  LineClears get completingLines => _lines;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final c = layout.cell;
    final pulse = 0.35 + 0.3 * (0.5 + 0.5 * sin(_t * 9));
    _linePaint.color = const Color(0xFFFFD54F).withValues(alpha: pulse);
    for (final r in _lines.rows) {
      canvas.drawRect(Rect.fromLTWH(0, r * c, size.x, c), _linePaint);
    }
    for (final col in _lines.cols) {
      canvas.drawRect(Rect.fromLTWH(col * c, 0, c, size.y), _linePaint);
    }
    for (final o in _ghost) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.col * c + 1, o.row * c + 1, c - 2, c - 2),
          const Radius.circular(4),
        ),
        _ghostPaint,
      );
    }
  }
}
