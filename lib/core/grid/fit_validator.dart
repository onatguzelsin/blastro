import '../polyomino/polyomino_shape.dart';
import 'grid_matrix.dart';

abstract final class FitValidator {
  /// True if [piece] with its top-left at ([row], [col]) is fully in bounds
  /// and only covers empty squares.
  static bool canPlace(GridMatrix grid, Polyomino piece, int row, int col) {
    for (final o in piece.cells) {
      final r = row + o.row;
      final c = col + o.col;
      if (!grid.inBounds(r, c) || grid.isOccupied(r, c)) return false;
    }
    return true;
  }

  /// Every legal top-left anchor for [piece] as (row, col) pairs.
  static List<CellOffset> placements(GridMatrix grid, Polyomino piece) => [
    for (var r = 0; r <= GridMatrix.size - piece.height; r++)
      for (var c = 0; c <= GridMatrix.size - piece.width; c++)
        if (canPlace(grid, piece, r, c)) CellOffset(r, c),
  ];

  static bool fitsAnywhere(
    GridMatrix grid,
    Polyomino piece, {
    bool allowRotation = false,
  }) {
    final shapes = allowRotation ? piece.variants : [piece];
    return shapes.any((s) => _fits(grid, s));
  }

  static bool _fits(GridMatrix grid, Polyomino piece) {
    for (var r = 0; r <= GridMatrix.size - piece.height; r++) {
      for (var c = 0; c <= GridMatrix.size - piece.width; c++) {
        if (canPlace(grid, piece, r, c)) return true;
      }
    }
    return false;
  }

  /// Grid Lockout: no remaining tray piece fits anywhere AND no Discard
  /// charge is left to escape with. An empty tray is never a lockout.
  static bool isLockedOut(
    GridMatrix grid,
    List<Polyomino> remainingTray, {
    required int discardsRemaining,
    bool allowRotation = false,
  }) {
    if (remainingTray.isEmpty || discardsRemaining > 0) return false;
    return !remainingTray.any(
      (p) => fitsAnywhere(grid, p, allowRotation: allowRotation),
    );
  }
}
