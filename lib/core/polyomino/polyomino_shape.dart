import 'block_color.dart';

/// A relative (row, col) cell offset inside a polyomino's bounding box.
class CellOffset {
  const CellOffset(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is CellOffset && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// An immutable polyomino. Cells are normalized so the top-left of the
/// bounding box is (0,0) and are sorted row-major.
class Polyomino {
  Polyomino(this.id, List<CellOffset> cells, {this.dangerTier = 1, this.color})
    : cells = List.unmodifiable(_normalize(cells)) {
    height = this.cells.map((c) => c.row).reduce((a, b) => a > b ? a : b) + 1;
    width = this.cells.map((c) => c.col).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Builds a shape from ASCII rows where `X` marks a filled cell.
  factory Polyomino.fromAscii(
    String id,
    List<String> rows, {
    int dangerTier = 1,
  }) {
    final cells = <CellOffset>[];
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        if (rows[r][c] == 'X') cells.add(CellOffset(r, c));
      }
    }
    return Polyomino(id, cells, dangerTier: dangerTier);
  }

  final String id;
  final List<CellOffset> cells;

  /// 1 (easy to place) .. 4 (hardest to fit on a crowded board).
  final int dangerTier;

  /// The color this piece was dealt in (null for an uncolored catalog shape).
  /// Its cells keep it when placed, and rotations keep it too.
  final BlockColor? color;

  late final int height;
  late final int width;

  int get cellCount => cells.length;

  Polyomino withColor(BlockColor? c) =>
      Polyomino(id, cells, dangerTier: dangerTier, color: c);

  /// All distinct orientations (4 rotations x optional mirror), starting with
  /// this shape itself. Only usable when rotation is unlocked
  /// (`joker_gyroscope` or a consumable).
  late final List<Polyomino> variants = _buildVariants();

  /// The next orientation in the rotation cycle (tap-to-rotate).
  Polyomino get nextVariant => variants.length > 1 ? variants[1] : this;

  List<Polyomino> _buildVariants() {
    final seen = <String>{};
    final out = <Polyomino>[];
    for (final mirror in [false, true]) {
      var shape = mirror
          ? cells.map((c) => CellOffset(c.row, -c.col)).toList()
          : cells;
      for (var i = 0; i < 4; i++) {
        final candidate = Polyomino(
          id,
          shape,
          dangerTier: dangerTier,
          color: color,
        );
        if (seen.add(candidate.cells.join())) out.add(candidate);
        shape = shape.map((c) => CellOffset(c.col, -c.row)).toList();
      }
    }
    return List.unmodifiable(out);
  }

  static List<CellOffset> _normalize(List<CellOffset> raw) {
    assert(raw.isNotEmpty, 'A polyomino needs at least one cell');
    final minRow = raw.map((c) => c.row).reduce((a, b) => a < b ? a : b);
    final minCol = raw.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    final shifted =
        raw.map((c) => CellOffset(c.row - minRow, c.col - minCol)).toList()
          ..sort(
            (a, b) => a.row != b.row
                ? a.row.compareTo(b.row)
                : a.col.compareTo(b.col),
          );
    return shifted;
  }

  @override
  String toString() => 'Polyomino($id)';
}
