import '../scoring/score_accumulator.dart';
import '../scoring/score_step_event.dart';
import 'joker_effects.dart';
import 'joker_hooks.dart';

/// Runs joker hooks and turns their bonuses into replayable score events.
abstract final class JokerScoringHooks {
  /// `1 + (x - 1) * scale`; scale 0.5 turns x2 into x1.5.
  static double scaleX(double x, double scale) => 1 + (x - 1) * scale;

  static void applyBonus(
    ScoreAccumulator acc,
    JokerBonus bonus, {
    required ScorePhase phase,
    required String label,
    required int slot,
    int? row,
    int? col,
    double xMultScale = 1.0,
  }) {
    if (bonus.isNone) return;
    final x = scaleX(bonus.xMult, xMultScale);
    final kind = switch (phase) {
      ScorePhase.clearedCells => ScoreStepKind.jokerCell,
      ScorePhase.residue => ScoreStepKind.jokerResidue,
      _ =>
        x != 1.0
            ? ScoreStepKind.jokerXMult
            : bonus.mult != 0
            ? ScoreStepKind.jokerMult
            : ScoreStepKind.jokerChips,
    };
    acc.add(
      phase: phase,
      kind: kind,
      label: row == null ? label : '$label ($row,$col)',
      addChips: bonus.chips,
      addMult: bonus.mult,
      xMult: x,
      row: row,
      col: col,
      jokerIndex: slot,
    );
  }

  /// Phase 2: every joker's `onCellScored`, left to right.
  static void cell(
    ScoreAccumulator acc,
    List<ResolvedJoker> bar,
    CellScoredContext ctx,
  ) {
    for (final r in bar) {
      final hook = r.joker.onCellScored;
      if (hook == null) continue;
      applyBonus(
        acc,
        hook(ctx),
        phase: ScorePhase.clearedCells,
        label: r.joker.id,
        slot: r.slot,
        row: ctx.row,
        col: ctx.col,
      );
    }
  }

  /// Phase 3: every joker's `onResidueScanned`, left to right.
  static void residue(
    ScoreAccumulator acc,
    List<ResolvedJoker> bar,
    ResidueScanContext ctx,
  ) {
    for (final r in bar) {
      final hook = r.joker.onResidueScanned;
      if (hook == null) continue;
      applyBonus(
        acc,
        hook(ctx),
        phase: ScorePhase.residue,
        label: r.joker.id,
        slot: r.slot,
        row: ctx.row,
        col: ctx.col,
      );
    }
  }
}
