import '../polyomino/polyomino_shape.dart';
import 'grid_cell.dart';

/// The 8x8 board. Empty squares are `null`.
class GridMatrix {
  GridMatrix()
    : _cells = List.generate(size, (_) => List<GridCell?>.filled(size, null));

  GridMatrix._(this._cells);

  /// Test/debug helper: `X` = plain occupied cell, anything else empty.
  /// Missing rows/columns are treated as empty.
  factory GridMatrix.fromAscii(List<String> rows) {
    final grid = GridMatrix();
    for (var r = 0; r < rows.length && r < size; r++) {
      for (var c = 0; c < rows[r].length && c < size; c++) {
        if (rows[r][c] == 'X') grid._cells[r][c] = GridCell.plain;
      }
    }
    return grid;
  }

  /// Inverse of [toJson]: 8 rows of 8 entries, each `null` or a cell map.
  factory GridMatrix.fromJson(List<dynamic> rows) {
    final grid = GridMatrix();
    for (var r = 0; r < size; r++) {
      final row = rows[r] as List<dynamic>;
      for (var c = 0; c < size; c++) {
        final cell = row[c] as Map<String, dynamic>?;
        grid._cells[r][c] = cell == null ? null : GridCell.fromJson(cell);
      }
    }
    return grid;
  }

  static const int size = 8;

  final List<List<GridCell?>> _cells;

  List<List<Map<String, String>?>> toJson() => [
    for (final row in _cells) [for (final cell in row) cell?.toJson()],
  ];

  GridMatrix copy() =>
      GridMatrix._([for (final row in _cells) List<GridCell?>.of(row)]);

  bool inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  GridCell? at(int r, int c) => _cells[r][c];

  bool isOccupied(int r, int c) => _cells[r][c] != null;

  int get occupiedCount =>
      _cells.fold(0, (sum, row) => sum + row.where((c) => c != null).length);

  bool get isEmpty => occupiedCount == 0;

  void setCell(int r, int c, GridCell? cell) => _cells[r][c] = cell;

  /// Stamps [piece] with its top-left at ([row], [col]). Throws
  /// [RangeError] if out of bounds and [StateError] on overlap; nothing is
  /// written when it throws.
  void place(
    Polyomino piece,
    int row,
    int col, {
    GridCell cell = GridCell.plain,
  }) {
    for (final o in piece.cells) {
      final r = row + o.row;
      final c = col + o.col;
      if (!inBounds(r, c)) {
        throw RangeError('${piece.id} out of bounds at ($r,$c)');
      }
      if (isOccupied(r, c)) throw StateError('${piece.id} overlaps ($r,$c)');
    }
    for (final o in piece.cells) {
      _cells[row + o.row][col + o.col] = cell;
    }
  }

  /// Empties the given rows and columns simultaneously.
  void clearLines({
    Iterable<int> rows = const [],
    Iterable<int> cols = const [],
  }) {
    for (final r in rows) {
      for (var c = 0; c < size; c++) {
        _cells[r][c] = null;
      }
    }
    for (final c in cols) {
      for (var r = 0; r < size; r++) {
        _cells[r][c] = null;
      }
    }
  }
}
