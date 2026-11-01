import '../core/polyomino/block_bag.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/blind_transition.dart';
import 'run_placement.dart';
import 'run_state.dart';
import 'run_transitions.dart';

/// The Blind Select hub: leaving the shop, playing a blind, skipping one.
abstract final class RunBlindFlow {
  /// Parks a (new or advanced) run on the Blind Select screen.
  static RunState toHub(RunState s) =>
      s.copyWith(status: RunStatus.blindSelect, clearBoss: true);

  /// After the shop: apply the blind-transition rule (board persists unless
  /// a Boss fell; the old tray is discarded and a full new one is dealt),
  /// then show the next blind's card.
  static RunState enterHub(RunState s, BlockBag bag) {
    if (s.status != RunStatus.shopping) return s;
    final entry = BlindTransition.enterNext(
      ante: s.ante,
      blind: s.blind,
      grid: s.grid,
      bag: bag,
    );
    return s.copyWith(
      grid: entry.grid,
      tray: entry.tray,
      ante: entry.ante,
      blind: entry.blind,
      skipped: entry.boardReset ? const [] : s.skipped,
      status: RunStatus.blindSelect,
      clearShop: true,
      clearBoss: true,
    );
  }

  /// "Play Blind": set up trays, discards and the Boss, then start playing
  /// (and apply the lockout check to the dealt tray).
  static RunState play(RunState s, BlockBag bag) {
    if (s.status != RunStatus.blindSelect) return s;
    return RunPlacement.settle(
      RunTransitions.beginBlind(s.copyWith(status: RunStatus.playing)),
      bag,
    );
  }

  /// "Skip Blind" (Small/Big only): forfeit its reward and shop visit and
  /// move straight to the next blind. Board and tray are left untouched.
  static RunState skip(RunState s) {
    if (s.status != RunStatus.blindSelect || s.blind == BlindType.boss) {
      return s;
    }
    return s.copyWith(
      skipped: [...s.skipped, s.blind],
      blind: BlindTransition.nextBlind(s.blind),
    );
  }
}
