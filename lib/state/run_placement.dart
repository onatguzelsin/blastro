import 'dart:math';

import '../core/grid/fit_validator.dart';
import '../core/grid/line_detector.dart';
import '../core/polyomino/block_bag.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/scoring/scoring_pipeline.dart';
import 'run_state.dart';

/// Placing a piece and settling the consequences (blind clear, next tray,
/// both lose conditions). Pure apart from drawing from the [BlockBag].
abstract final class RunPlacement {
  static const _pipeline = ScoringPipeline();

  /// The state after placing tray [slot] at ([row], [col]), or null if the
  /// move is not legal.
  static RunState? place(RunState s, BlockBag bag, int slot, int row, int col) {
    final piece = s.tray[slot];
    if (s.status != RunStatus.playing || piece == null) return null;
    if (!FitValidator.canPlace(s.grid, piece, row, col)) return null;

    final placed = s.grid.copy()..place(piece, row, col);
    final cleared = !LineDetector.detect(placed).isEmpty;
    final combo = s.combo.afterPlacement(
      cleared: cleared,
      extraSetupMoves: s.modifiers.extraSetupMoves,
    );
    final result = _pipeline.score(
      board: placed,
      comboStreak: combo.streak,
      jokers: s.jokers,
      archetypeLevels: s.archetypeLevels,
      rng: Random(s.seed + s.placements),
      placedPiece: piece,
      boss: s.boss,
      usedArchetypes: s.archetypesThisBlind,
    );
    final after = placed.copy()
      ..clearLines(rows: result.clears.rows, cols: result.clears.cols);
    final scored = result.archetype;
    final used = scored != null && !s.archetypesThisBlind.contains(scored)
        ? [...s.archetypesThisBlind, scored]
        : s.archetypesThisBlind;
    final toothLoss = cleared ? (s.boss?.goldLossPerClear ?? 0) : 0;
    return settle(
      s.copyWith(
        grid: after,
        tray: [...s.tray]..[slot] = null,
        combo: combo,
        score: s.score + result.finalScore,
        gold: (s.gold - toothLoss).clamp(0, 1 << 30),
        archetypesThisBlind: used,
        placements: s.placements + 1,
        scoreSerial: s.scoreSerial + 1,
        lastScore: result,
        preClearBoard: placed,
      ),
      bag,
    );
  }

  /// Applies the blind-clear, tray-advance and both lose conditions.
  static RunState settle(RunState next, BlockBag bag) {
    var s = next;
    if (s.score >= s.target) {
      // Only the first Finisher ends the run; later ones (Endless) just clear.
      final wins = !s.endless && AnteScaling.isFinisher(s.ante, s.blind);
      return s.copyWith(
        status: wins ? RunStatus.victory : RunStatus.blindCleared,
      );
    }
    if (s.unplaced.isEmpty) {
      final trays = s.traysRemaining - 1;
      if (trays <= 0) {
        return s.copyWith(traysRemaining: 0, status: RunStatus.lost);
      }
      s = s.copyWith(traysRemaining: trays, tray: bag.drawTray());
    }
    final locked = FitValidator.isLockedOut(
      s.grid,
      s.unplaced,
      discardsRemaining: s.discards,
      allowRotation: s.modifiers.rotation,
    );
    return locked ? s.copyWith(status: RunStatus.lost) : s;
  }
}
