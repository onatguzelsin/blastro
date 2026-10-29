import 'dart:math';

import '../grid/grid_matrix.dart';
import '../grid/line_detector.dart';
import '../polyomino/polyomino_shape.dart';
import '../roguelite/boss_blinds.dart';
import '../roguelite/joker_effects.dart';
import '../roguelite/joker_hooks.dart';
import '../roguelite/run_modifiers.dart';
import 'cell_scoring.dart';
import 'clear_archetypes.dart';
import 'score_accumulator.dart';
import 'score_step_event.dart';

class ScoreResult {
  const ScoreResult({
    required this.archetype,
    required this.clears,
    required this.totalChips,
    required this.totalMult,
    required this.allClearBonus,
    required this.finalScore,
    required this.events,
    this.blockedByBoss = false,
  });

  /// Null when the placement cleared nothing (score 0, no events).
  final ClearArchetype? archetype;
  final LineClears clears;
  final double totalChips;
  final double totalMult;
  final int allClearBonus;
  final int finalScore;

  /// Ordered steps for Flame animations and haptics to replay.
  final List<ScoreStepEvent> events;

  /// Lines cleared but a boss rule (Eye/Mouth) scored them for 0.
  final bool blockedByBoss;
}

/// 4-phase deterministic scoring:
/// `FinalMoveScore = (TotalChips * TotalMult).floor() + allClearBonus`.
class ScoringPipeline {
  const ScoringPipeline();

  /// [board] is the grid AFTER the piece was placed but BEFORE lines are
  /// removed. This method never mutates it. [comboStreak] is the active
  /// streak (see `ComboWindow.afterPlacement`). Lucky cells draw from [rng].
  /// [boss] is the active Boss Blind (if any) and [usedArchetypes] the clear
  /// types that already scored this blind, for The Eye / The Mouth.
  ScoreResult score({
    required GridMatrix board,
    required int comboStreak,
    List<Joker> jokers = const [],
    Map<ClearArchetype, int> archetypeLevels = const {},
    Random? rng,
    Polyomino? placedPiece,
    BossBlind? boss,
    List<ClearArchetype> usedArchetypes = const [],
  }) {
    final clears = LineDetector.detect(board);
    final after = board.copy()
      ..clearLines(rows: clears.rows, cols: clears.cols);
    final archetype = ClearArchetypes.classify(
      clears,
      boardEmptyAfter: after.isEmpty,
    );
    if (archetype == null) return _empty(clears, blocked: false);
    if (boss != null &&
        !boss.allowsArchetype(
          archetype.name,
          usedArchetypes.map((a) => a.name).toList(),
        )) {
      return _empty(clears, blocked: true);
    }

    final mods = RunModifiers.fromJokers(jokers);
    final bar = JokerBar.resolved(jokers);
    final rules = CellRules(
      jokers: bar,
      ignoreEffects: boss?.ignoreCellEffects ?? false,
      luckyAlways: mods.luckyAlways,
      steelMultiplier: mods.steelMultiplier,
      residueRetriggers: JokerBar.residueRetriggers(jokers),
    );
    final acc = ScoreAccumulator();

    // Phase 1: geometry base + active combo streak.
    final level = archetypeLevels[archetype] ?? 1;
    final base = ClearArchetypes.base[archetype]!;
    final baseScale = (boss?.halveBase ?? false) ? 0.5 : 1.0;
    acc.add(
      phase: ScorePhase.geometry,
      kind: ScoreStepKind.archetypeBase,
      label: archetype.name,
      addChips: base.chipsAt(level) * baseScale,
      addMult: base.multAt(level) * baseScale,
    );
    if (comboStreak > 0) {
      acc.add(
        phase: ScorePhase.geometry,
        kind: ScoreStepKind.comboStreak,
        label: 'combo x$comboStreak',
        addMult: comboStreak.toDouble(),
      );
    }

    // Phase 2: cleared cells (Cross Clear intersections trigger twice).
    CellScoring.scoreCleared(acc, board, clears, rng ?? Random(0), rules);

    // Phase 3: board residue (0,0) -> (7,7).
    if (!(boss?.disableResidue ?? false)) {
      CellScoring.scoreResidue(acc, after, rules);
    }

    // Phase 4: joker bar, strictly left to right.
    JokerBar.apply(
      acc,
      jokers,
      move: MoveContext(
        archetype: archetype,
        clears: clears,
        residue: after,
        comboStreak: comboStreak,
        placedPiece: placedPiece,
      ),
      xMultScale: (boss?.halveXMult ?? false) ? 0.5 : 1.0,
    );

    final bonus = archetype == ClearArchetype.cleanSweep
        ? ClearArchetypes.allClearBonus
        : 0;
    if (bonus > 0) {
      acc.add(
        phase: ScorePhase.jokers,
        kind: ScoreStepKind.allClearBonus,
        label: 'all clear',
        flat: bonus,
      );
    }
    final finalScore = acc.total;
    acc.add(
      phase: ScorePhase.jokers,
      kind: ScoreStepKind.finalScore,
      label: 'final $finalScore',
    );
    return ScoreResult(
      archetype: archetype,
      clears: clears,
      totalChips: acc.chips,
      totalMult: acc.mult,
      allClearBonus: bonus,
      finalScore: finalScore,
      events: List.unmodifiable(acc.events),
    );
  }

  ScoreResult _empty(LineClears clears, {required bool blocked}) => ScoreResult(
    archetype: null,
    clears: clears,
    totalChips: 0,
    totalMult: 0,
    allClearBonus: 0,
    finalScore: 0,
    events: const [],
    blockedByBoss: blocked,
  );
}
