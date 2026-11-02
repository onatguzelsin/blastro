import '../core/grid/fit_validator.dart';
import '../core/polyomino/block_bag.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/quick_play_rescue.dart';
import '../core/scoring/combo_window.dart';
import 'quick_play_event.dart';
import '../core/scoring/score_preview.dart';
import 'run_state.dart';

/// Placing a piece and settling the consequences (blind clear, next tray,
/// both lose conditions). Pure apart from drawing from the [BlockBag].
abstract final class RunPlacement {
  /// The state after placing tray [slot] at ([row], [col]), or null if the
  /// move is not legal.
  static RunState? place(RunState s, BlockBag bag, int slot, int row, int col) {
    final sim = preview(s, slot, row, col);
    final piece = s.tray[slot];
    if (sim == null || piece == null) return null;
    final result = sim.result;
    final scored = result.archetype;
    final used = scored != null && !s.archetypesThisBlind.contains(scored)
        ? [...s.archetypesThisBlind, scored]
        : s.archetypesThisBlind;
    final toothLoss = sim.clears ? (s.boss?.goldLossPerClear ?? 0) : 0;
    // Quick Play: +1 tray for every cell this move cleared.
    final refund = s.mode.trayRefund(result.clears);
    return settle(
      s.copyWith(
        grid: sim.after,
        tray: [...s.tray]..[slot] = null,
        combo: sim.combo,
        score: s.score + result.finalScore,
        gold: (s.gold - toothLoss).clamp(0, 1 << 30),
        archetypesThisBlind: used,
        traysRemaining: s.traysRemaining + refund,
        quickEvent: refund > 0
            ? QuickPlayEvent(trayRefund: refund)
            : QuickPlayEvent.none,
        placements: s.placements + 1,
        scoreSerial: s.scoreSerial + 1,
        lastScore: result,
        preClearBoard: sim.placed,
      ),
      bag,
    );
  }

  /// What placing tray [slot] at ([row], [col]) would do, or null if illegal.
  /// The real [place] scores through this same call, so a preview always
  /// equals the move that follows it.
  static PlacementPreview? preview(RunState s, int slot, int row, int col) {
    final piece = s.tray[slot];
    if (s.status != RunStatus.playing || piece == null) return null;
    return simulatePlacementPreview(
      grid: s.grid,
      piece: piece,
      row: row,
      col: col,
      combo: s.combo,
      rngSeed: s.seed + s.placements,
      jokers: s.jokers,
      archetypeLevels: s.archetypeLevels,
      boss: s.boss,
      usedArchetypes: s.archetypesThisBlind,
    );
  }

  /// Applies the blind-clear, tray-advance and both lose conditions. Quick
  /// Play has neither blinds nor a game over: see [_settleQuickPlay].
  static RunState settle(RunState next, BlockBag bag) {
    if (next.mode.isQuickPlay) return _settleQuickPlay(next, bag);
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

  /// Endless rules. No target, no blinds, no game over:
  /// * out of trays -> Second Wind: a fresh batch of the starting trays;
  /// * nothing fits and no discards -> Rescue: the fullest rows are cleared
  ///   until something fits.
  /// Both break the combo. Pieces are dealt with the board in view so a
  /// crowded board gets a little help.
  static RunState _settleQuickPlay(RunState next, BlockBag bag) {
    var s = next;
    var event = s.quickEvent;
    if (s.unplaced.isEmpty) {
      var trays = s.traysRemaining - 1;
      var combo = s.combo;
      if (trays <= 0) {
        trays = s.deck.traysPerBlind;
        event = event.copyWith(windTrays: trays);
        combo = const ComboWindow();
      }
      s = s.copyWith(
        traysRemaining: trays,
        combo: combo,
        tray: bag.drawTray(board: s.grid),
      );
    }
    final locked = FitValidator.isLockedOut(
      s.grid,
      s.unplaced,
      discardsRemaining: s.discards,
      allowRotation: s.modifiers.rotation,
    );
    if (locked) {
      final rescue = QuickPlayRescue.rescue(
        s.grid,
        s.unplaced,
        allowRotation: s.modifiers.rotation,
      );
      s = s.copyWith(grid: rescue.grid, combo: const ComboWindow());
      event = event.copyWith(rescuedRows: rescue.rowsCleared);
    }
    return identical(event, next.quickEvent)
        ? s
        : s.copyWith(quickEvent: event);
  }
}
