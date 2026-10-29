import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final layout = GameLayout.compute(
    Vector2(360, 800),
    topInset: 24,
    bottomInset: 16,
  );

  test('finger offset is 80dp straight up', () {
    expect(GameLayout.fingerOffset, Vector2(0, -80));
    expect(layout.dragCenter(Vector2(100, 500)), Vector2(100, 420));
  });

  test('board is square, centered and fits width and height', () {
    expect(layout.boardOrigin.x * 2 + layout.boardSide, closeTo(360, 0.01));
    expect(layout.boardOrigin.y, 24 + GameLayout.hudReserve);
    expect(layout.trayTop + layout.trayHeight, lessThanOrEqualTo(800 - 16));
  });

  test('snap: piece centered over a cell maps to that cell', () {
    final dot = PolyominoCatalog.byId('dot');
    final c = layout.cellCenter(3, 5);
    expect(layout.snap(c, dot), (row: 3, col: 5));
    expect(layout.snap(c + Vector2.all(layout.cell * 0.4), dot), (
      row: 3,
      col: 5,
    ));
  });

  test('snap uses the piece top-left (multi-cell pieces)', () {
    final rect = PolyominoCatalog.byId('rect_2x3'); // 2 rows x 3 cols
    final center =
        layout.cellTopLeft(2, 1) +
        Vector2(3 * layout.cell / 2, 2 * layout.cell / 2);
    expect(layout.snap(center, rect), (row: 2, col: 1));
  });

  test('touch point maps through the 80dp offset', () {
    final dot = PolyominoCatalog.byId('dot');
    final target = layout.cellCenter(4, 4);
    final touch = target - GameLayout.fingerOffset; // finger 80dp below
    expect(layout.snap(layout.dragCenter(touch), dot), (row: 4, col: 4));
  });

  test('off-board drops snap outside 0..7', () {
    final dot = PolyominoCatalog.byId('dot');
    final s = layout.snap(Vector2(5, 5), dot);
    expect(s.col, lessThan(0));
  });

  test('small phones shrink the cells instead of overflowing', () {
    final small = GameLayout.compute(Vector2(320, 600), topInset: 24);
    expect(small.trayTop + small.trayHeight, lessThanOrEqualTo(600));
  });
}
