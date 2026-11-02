import 'grid_matrix.dart';

/// Rows and columns that are completely filled, in ascending order.
class LineClears {
  const LineClears({this.rows = const [], this.cols = const []});

  final List<int> rows;
  final List<int> cols;

  int get lineCount => rows.length + cols.length;

  /// How many DISTINCT cells these lines clear. A cell where a cleared row
  /// and column cross is counted once: one line = 8, a Cross Clear = 15,
  /// two parallel lines = 16.
  int get cellCount =>
      (rows.length + cols.length) * GridMatrix.size - rows.length * cols.length;
  bool get isEmpty => lineCount == 0;
}

abstract final class LineDetector {
  /// Detects every full row and column in a single pass, so row and column
  /// clears triggered by one placement are reported together (Cross Clear).
  static LineClears detect(GridMatrix grid) {
    final rows = <int>[];
    final cols = <int>[];
    for (var i = 0; i < GridMatrix.size; i++) {
      if (List.generate(
        GridMatrix.size,
        (c) => grid.isOccupied(i, c),
      ).every((filled) => filled)) {
        rows.add(i);
      }
      if (List.generate(
        GridMatrix.size,
        (r) => grid.isOccupied(r, i),
      ).every((filled) => filled)) {
        cols.add(i);
      }
    }
    return LineClears(rows: rows, cols: cols);
  }
}
