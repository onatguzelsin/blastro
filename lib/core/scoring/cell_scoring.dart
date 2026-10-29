import 'dart:math';

import '../grid/grid_cell.dart';
import '../grid/grid_matrix.dart';
import '../grid/line_detector.dart';
import '../roguelite/joker_effects.dart';
import '../roguelite/joker_hooks.dart';
import '../roguelite/joker_scoring_hooks.dart';
import 'score_accumulator.dart';
import 'score_step_event.dart';

abstract final class CellScoreValues {
  static const double baseChips = 10;
  static const double bonusChips = 30;
  static const double multEnhancement = 4;
  static const double glassX = 2.0;
  static const double luckyMult = 20;
  static const int luckyOdds = 5; // 1 in 5
  static const double foilChips = 50;
  static const double holoMult = 10;
  static const double polychromeX = 1.5;
}

/// Rule switches for Phases 2 and 3 (from jokers and the active boss).
class CellRules {
  const CellRules({
    this.jokers = const [],
    this.ignoreEffects = false,
    this.luckyAlways = false,
    this.steelMultiplier = 1.5,
    this.residueRetriggers = 0,
  });

  /// Effective jokers (Blueprint/Brainstorm resolved), left to right.
  final List<ResolvedJoker> jokers;

  /// Enhancements and editions do nothing (The Window).
  final bool ignoreEffects;
  final bool luckyAlways;
  final double steelMultiplier;
  final int residueRetriggers;
}

abstract final class CellScoring {
  /// Phase 2: rows left-to-right (c=0..7) in ascending row order, then
  /// columns top-to-bottom (r=0..7). A cell in both a cleared row and a
  /// cleared column (the Cross Clear intersection) is visited -- and so
  /// triggers -- twice. Red Seals retrigger a visit once.
  static void scoreCleared(
    ScoreAccumulator acc,
    GridMatrix board,
    LineClears clears,
    Random rng,
    CellRules rules,
  ) {
    for (final r in clears.rows) {
      for (var c = 0; c < GridMatrix.size; c++) {
        _visit(
          acc,
          r,
          c,
          board.at(r, c),
          rng,
          rules,
          intersection: clears.cols.contains(c),
        );
      }
    }
    for (final c in clears.cols) {
      for (var r = 0; r < GridMatrix.size; r++) {
        _visit(
          acc,
          r,
          c,
          board.at(r, c),
          rng,
          rules,
          intersection: clears.rows.contains(r),
        );
      }
    }
  }

  static void _visit(
    ScoreAccumulator acc,
    int r,
    int c,
    GridCell? cell,
    Random rng,
    CellRules rules, {
    required bool intersection,
  }) {
    if (cell == null) return;
    final triggers = cell.seal == CellSeal.red ? 2 : 1;
    for (var t = 0; t < triggers; t++) {
      _trigger(acc, r, c, cell, rng, rules, retrigger: t > 0);
      JokerScoringHooks.cell(
        acc,
        rules.jokers,
        CellScoredContext(
          row: r,
          col: c,
          cell: cell,
          isIntersection: intersection,
        ),
      );
    }
  }

  static void _trigger(
    ScoreAccumulator acc,
    int r,
    int c,
    GridCell cell,
    Random rng,
    CellRules rules, {
    required bool retrigger,
  }) {
    final tag = '($r,$c)${retrigger ? ' retrigger' : ''}';
    void step(
      ScoreStepKind kind,
      String name, {
      double chips = 0,
      double mult = 0,
      double x = 1,
    }) => acc.add(
      phase: ScorePhase.clearedCells,
      kind: kind,
      label: '$name $tag',
      addChips: chips,
      addMult: mult,
      xMult: x,
      row: r,
      col: c,
    );
    step(ScoreStepKind.cellChips, 'cell', chips: CellScoreValues.baseChips);
    if (rules.ignoreEffects) return;
    const enh = ScoreStepKind.cellEnhancement;
    switch (cell.enhancement) {
      case CellEnhancement.bonus:
        step(enh, 'bonus', chips: CellScoreValues.bonusChips);
      case CellEnhancement.mult:
        step(enh, 'mult', mult: CellScoreValues.multEnhancement);
      case CellEnhancement.glass:
        step(enh, 'glass', x: CellScoreValues.glassX);
      case CellEnhancement.lucky:
        if (rules.luckyAlways || rng.nextInt(CellScoreValues.luckyOdds) == 0) {
          step(enh, 'lucky', mult: CellScoreValues.luckyMult);
        }
      case CellEnhancement.steel: // Steel only scores as board residue.
      case CellEnhancement.none:
        break;
    }
    const ed = ScoreStepKind.cellEdition;
    switch (cell.edition) {
      case CellEdition.foil:
        step(ed, 'foil', chips: CellScoreValues.foilChips);
      case CellEdition.holo:
        step(ed, 'holo', mult: CellScoreValues.holoMult);
      case CellEdition.polychrome:
        step(ed, 'polychrome', x: CellScoreValues.polychromeX);
      case CellEdition.none:
        break;
    }
  }

  /// Phase 3: remaining occupied cells scanned (0,0) -> (7,7) row-major.
  /// Steel grants its Mult factor (x1.5, more with Baron of Steel); each
  /// residue retrigger (Mime) repeats it. Residue joker hooks fire per cell.
  static void scoreResidue(
    ScoreAccumulator acc,
    GridMatrix after,
    CellRules rules,
  ) {
    for (var r = 0; r < GridMatrix.size; r++) {
      for (var c = 0; c < GridMatrix.size; c++) {
        final cell = after.at(r, c);
        if (cell == null) continue;
        if (!rules.ignoreEffects && cell.enhancement == CellEnhancement.steel) {
          for (var t = 0; t <= rules.residueRetriggers; t++) {
            acc.add(
              phase: ScorePhase.residue,
              kind: ScoreStepKind.residueSteel,
              label: 'steel ($r,$c)${t > 0 ? ' retrigger' : ''}',
              xMult: rules.steelMultiplier,
              row: r,
              col: c,
            );
          }
        }
        JokerScoringHooks.residue(
          acc,
          rules.jokers,
          ResidueScanContext(row: r, col: c, cell: cell),
        );
      }
    }
  }
}
