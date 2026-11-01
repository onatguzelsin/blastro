import 'dart:math';

import 'package:flame/components.dart';

import '../core/grid/grid_matrix.dart';
import '../core/polyomino/polyomino_shape.dart';

/// Portrait layout for the Flame canvas: board under the HUD overlays, tray
/// at the bottom. All values are logical pixels (dp).
class GameLayout {
  GameLayout._({
    required this.cell,
    required this.boardOrigin,
    required this.trayTop,
    required this.trayHeight,
  });

  /// Space under the status bar reserved for the joker bar + HUD overlays.
  static const double hudReserve = 318;
  static const double sideMargin = 12;
  static const double trayScale = 0.5;
  static const int traySlots = 3;

  /// Mandatory touch ergonomics: a dragged piece is drawn 80dp above the
  /// touch point so the thumb never covers the cells.
  static final Vector2 fingerOffset = Vector2(0, -80);

  final double cell;
  final Vector2 boardOrigin;
  final double trayTop;
  final double trayHeight;

  double get boardSide => cell * GridMatrix.size;

  factory GameLayout.compute(
    Vector2 size, {
    double topInset = 0,
    double bottomInset = 0,
  }) {
    final top = topInset + hudReserve;
    final byWidth = (size.x - sideMargin * 2) / GridMatrix.size;
    // board (8c) + gap + tray (5 cells at trayScale) must fit the height.
    final byHeight = (size.y - top - bottomInset - 44) / (8 + 5 * trayScale);
    final cell = max(8.0, min(byWidth, byHeight));
    final boardX = (size.x - cell * GridMatrix.size) / 2;
    final trayHeight = cell * 5 * trayScale;
    return GameLayout._(
      cell: cell,
      boardOrigin: Vector2(boardX, top),
      trayTop: top + cell * GridMatrix.size + 20,
      trayHeight: trayHeight,
    );
  }

  Vector2 cellTopLeft(int row, int col) =>
      boardOrigin + Vector2(col * cell, row * cell);

  Vector2 cellCenter(int row, int col) =>
      cellTopLeft(row, col) + Vector2.all(cell / 2);

  Vector2 get boardCenter => boardOrigin + Vector2.all(boardSide / 2);

  /// Center of tray slot [i] (the board is as wide as the tray).
  Vector2 trayCenter(int i) {
    final slotW = boardSide / traySlots;
    return Vector2(boardOrigin.x + slotW * (i + 0.5), trayTop + trayHeight / 2);
  }

  Vector2 get traySlotSize => Vector2(boardSide / traySlots, trayHeight);

  /// Where the dragged piece's CENTER is drawn for a given touch point.
  Vector2 dragCenter(Vector2 touch) => touch + fingerOffset;

  /// Snaps a piece drawn at 1.0x with its center at [center] to the board
  /// cell its top-left corner is nearest. May be off-board; callers validate.
  ({int row, int col}) snap(Vector2 center, Polyomino piece) {
    final topLeft =
        center - Vector2(piece.width * cell, piece.height * cell) / 2;
    return (
      row: ((topLeft.y - boardOrigin.y) / cell).round(),
      col: ((topLeft.x - boardOrigin.x) / cell).round(),
    );
  }
}
