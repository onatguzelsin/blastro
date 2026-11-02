import '../grid/fit_validator.dart';
import '../grid/grid_matrix.dart';
import '../polyomino/polyomino_shape.dart';
import 'run_mode.dart';

/// What a Rescue did to the board.
class RescueResult {
  const RescueResult({required this.grid, required this.rowsCleared});

  final GridMatrix grid;
  final int rowsCleared;
}

/// Quick Play never ends in a lockout. When no tray piece fits and there are
/// no discards left, the fullest rows are cleared (at least three) until
/// something fits, or the board is empty. Rescues award no score and no trays.
abstract final class QuickPlayRescue {
  /// Rows ordered fullest first (ties: the higher row first, so the bottom of
  /// the board is cleared before the top).
  static List<int> _rowsFullestFirst(GridMatrix grid) {
    final counts =
        [
          for (var r = 0; r < GridMatrix.size; r++)
            (
              r,
              [for (var c = 0; c < GridMatrix.size; c++) grid.isOccupied(r, c)]
                  .where((x) => x)
                  .length,
            ),
        ]..sort(
          (a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : b.$1.compareTo(a.$1),
        );
    return [
      for (final (r, n) in counts)
        if (n > 0) r,
    ];
  }

  /// Returns a rescued COPY of [grid]; the input is untouched.
  static RescueResult rescue(
    GridMatrix grid,
    List<Polyomino> pieces, {
    bool allowRotation = false,
  }) {
    final out = grid.copy();
    final order = _rowsFullestFirst(out);
    var cleared = 0;
    for (final row in order) {
      final enough = cleared >= QuickPlay.rescueMinRows;
      if (enough &&
          pieces.any(
            (p) =>
                FitValidator.fitsAnywhere(out, p, allowRotation: allowRotation),
          )) {
        break;
      }
      out.clearLines(rows: [row]);
      cleared++;
    }
    return RescueResult(grid: out, rowsCleared: cleared);
  }
}
