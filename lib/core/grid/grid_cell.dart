import '../polyomino/block_color.dart';

enum CellEnhancement { none, bonus, mult, glass, lucky, steel }

enum CellEdition { none, foil, holo, polychrome }

enum CellSeal { none, red }

/// Contents of one occupied grid square. An empty square is `null`.
class GridCell {
  const GridCell({
    this.enhancement = CellEnhancement.none,
    this.edition = CellEdition.none,
    this.seal = CellSeal.none,
    this.color,
  });

  static const GridCell plain = GridCell();

  factory GridCell.fromJson(Map<String, dynamic> json) => GridCell(
    enhancement: CellEnhancement.values.byName(
      (json['e'] as String?) ?? CellEnhancement.none.name,
    ),
    edition: CellEdition.values.byName(
      (json['d'] as String?) ?? CellEdition.none.name,
    ),
    seal: CellSeal.values.byName((json['s'] as String?) ?? CellSeal.none.name),
    color: json['c'] == null
        ? null
        : BlockColor.values.byName(json['c'] as String),
  );

  final CellEnhancement enhancement;
  final CellEdition edition;
  final CellSeal seal;

  /// The color the block was dealt in (null for cells made without one).
  /// It is not an enhancement: a colored plain cell is still `!isEnhanced`.
  final BlockColor? color;

  bool get isEnhanced =>
      enhancement != CellEnhancement.none ||
      edition != CellEdition.none ||
      seal != CellSeal.none;

  GridCell copyWith({
    CellEnhancement? enhancement,
    CellEdition? edition,
    CellSeal? seal,
    BlockColor? color,
  }) => GridCell(
    enhancement: enhancement ?? this.enhancement,
    edition: edition ?? this.edition,
    seal: seal ?? this.seal,
    color: color ?? this.color,
  );

  /// Compact: default fields are omitted.
  Map<String, String> toJson() => {
    if (enhancement != CellEnhancement.none) 'e': enhancement.name,
    if (edition != CellEdition.none) 'd': edition.name,
    if (seal != CellSeal.none) 's': seal.name,
    if (color != null) 'c': color!.name,
  };
}
