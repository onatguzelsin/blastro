import '../grid/grid_cell.dart';
import '../grid/grid_matrix.dart';
import '../grid/line_detector.dart';
import '../polyomino/polyomino_shape.dart';
import '../scoring/clear_archetypes.dart';

/// What a joker hook contributes to the running Chips/Mult.
class JokerBonus {
  const JokerBonus({this.chips = 0, this.mult = 0, this.xMult = 1.0});

  static const JokerBonus none = JokerBonus();

  final double chips;
  final double mult;
  final double xMult;

  bool get isNone => chips == 0 && mult == 0 && xMult == 1.0;
}

/// Phase 4 context: the whole move, after lines were removed.
class MoveContext {
  const MoveContext({
    required this.archetype,
    required this.clears,
    required this.residue,
    required this.comboStreak,
    this.placedPiece,
  });

  final ClearArchetype archetype;
  final LineClears clears;

  /// Board after the clear (what Phase 3 scanned).
  final GridMatrix residue;
  final int comboStreak;
  final Polyomino? placedPiece;
}

/// Phase 2 context: one cleared-cell trigger.
class CellScoredContext {
  const CellScoredContext({
    required this.row,
    required this.col,
    required this.cell,
    required this.isIntersection,
  });

  final int row;
  final int col;
  final GridCell cell;

  /// Cell sits in a cleared row AND a cleared column (Cross Clear).
  final bool isIntersection;
}

/// Phase 3 context: one occupied residue cell.
class ResidueScanContext {
  const ResidueScanContext({
    required this.row,
    required this.col,
    required this.cell,
  });

  final int row;
  final int col;
  final GridCell cell;
}

typedef MoveHook = JokerBonus Function(MoveContext context);
typedef CellScoredHook = JokerBonus Function(CellScoredContext context);
typedef ResidueScannedHook = JokerBonus Function(ResidueScanContext context);
