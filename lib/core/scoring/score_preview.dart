import 'dart:math';

import '../grid/fit_validator.dart';
import '../grid/grid_matrix.dart';
import '../grid/line_detector.dart';
import '../polyomino/polyomino_shape.dart';
import '../roguelite/boss_blinds.dart';
import '../roguelite/joker_effects.dart';
import '../roguelite/run_modifiers.dart';
import 'clear_archetypes.dart';
import 'combo_window.dart';
import 'scoring_pipeline.dart';

/// The exact outcome of dropping [piece] at a spot. Used both for the live
/// hover preview and for the real placement, so the two can never disagree.
class PlacementPreview {
  const PlacementPreview({
    required this.placed,
    required this.after,
    required this.combo,
    required this.result,
    required this.archetype,
    this.blockedBy,
    this.blockedById,
  });

  /// The board right after placing, before any line is removed.
  final GridMatrix placed;

  /// The board after the clear.
  final GridMatrix after;

  /// The combo window after this placement.
  final ComboWindow combo;
  final ScoreResult result;

  /// The geometric clear type, or null if nothing clears. Set even when a boss
  /// blanks the score, so the HUD can still name it.
  final ClearArchetype? archetype;

  /// Name of the boss that scores this clear for 0 (The Eye / The Mouth).
  final String? blockedBy;

  /// Id of that boss, so the HUD can show its translated name.
  final String? blockedById;

  bool get clears => !result.clears.isEmpty;
  double get chips => result.totalChips;
  double get mult => result.totalMult;
  int get score => result.finalScore;

  /// What the HUD needs, with value equality so a repeated hover is a no-op.
  PreviewSummary? get summary {
    final a = archetype;
    if (a == null) return null;
    return PreviewSummary(
      title: previewTitle(a),
      chips: blockedBy == null ? chips : 0,
      mult: blockedBy == null ? mult : 0,
      score: score,
      blockedBy: blockedBy,
      archetype: a,
      blockedById: blockedById,
    );
  }
}

/// The small, comparable part of a [PlacementPreview] shown in the HUD.
class PreviewSummary {
  const PreviewSummary({
    required this.title,
    required this.chips,
    required this.mult,
    required this.score,
    this.blockedBy,
    this.archetype,
    this.blockedById,
  });

  final String title;
  final double chips;
  final double mult;
  final int score;
  final String? blockedBy;

  /// The clear type and blocking boss's id, for translated HUD text. They
  /// follow from [title] and [blockedBy], so equality ignores them.
  final ClearArchetype? archetype;
  final String? blockedById;

  @override
  bool operator ==(Object other) =>
      other is PreviewSummary &&
      other.title == title &&
      other.chips == chips &&
      other.mult == mult &&
      other.score == score &&
      other.blockedBy == blockedBy;

  @override
  int get hashCode => Object.hash(title, chips, mult, score, blockedBy);
}

/// HUD names for the 10 clear types.
String previewTitle(ClearArchetype a) => switch (a) {
  ClearArchetype.single => 'SINGLE LINE',
  ClearArchetype.parallelDouble => 'PARALLEL DOUBLE!',
  ClearArchetype.crossClear => 'CROSS CLEAR!',
  ClearArchetype.triple => 'TRIPLE!',
  ClearArchetype.doubleCross => 'DOUBLE CROSS!',
  ClearArchetype.quad => 'QUAD!',
  ClearArchetype.zone3x3 => 'ZONE 3x3!',
  ClearArchetype.penta => 'PENTA!',
  ClearArchetype.hexa => 'HEXA!',
  ClearArchetype.cleanSweep => 'CLEAN SWEEP!',
};

/// Calculates what dropping [piece] with its top-left on ([row], [col]) would
/// do, or null if that spot is not legal.
///
/// Pure and side-effect free: it works on copies of [grid], never touches the
/// Block Bag (it takes none), and Lucky cells draw from a brand-new
/// `Random(rngSeed)`. Pass the seed the real placement uses
/// (`seed + placements`) and the preview matches the real result exactly.
PlacementPreview? simulatePlacementPreview({
  required GridMatrix grid,
  required Polyomino piece,
  required int row,
  required int col,
  required ComboWindow combo,
  required int rngSeed,
  List<Joker> jokers = const [],
  Map<ClearArchetype, int> archetypeLevels = const {},
  BossBlind? boss,
  List<ClearArchetype> usedArchetypes = const [],
}) {
  if (!FitValidator.canPlace(grid, piece, row, col)) return null;
  final placed = grid.copy()..place(piece, row, col);
  final lines = LineDetector.detect(placed);
  final nextCombo = combo.afterPlacement(
    cleared: !lines.isEmpty,
    extraSetupMoves: RunModifiers.fromJokers(jokers).extraSetupMoves,
  );
  final result = const ScoringPipeline().score(
    board: placed,
    comboStreak: nextCombo.streak,
    jokers: jokers,
    archetypeLevels: archetypeLevels,
    rng: Random(rngSeed),
    placedPiece: piece,
    boss: boss,
    usedArchetypes: usedArchetypes,
  );
  final after = placed.copy()
    ..clearLines(rows: result.clears.rows, cols: result.clears.cols);
  return PlacementPreview(
    placed: placed,
    after: after,
    combo: nextCombo,
    result: result,
    archetype: ClearArchetypes.classify(
      result.clears,
      boardEmptyAfter: after.isEmpty,
    ),
    blockedBy: result.blockedByBoss ? boss?.name : null,
    blockedById: result.blockedByBoss ? boss?.id : null,
  );
}
