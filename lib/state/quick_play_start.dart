import '../core/grid/grid_matrix.dart';
import '../core/polyomino/block_bag.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/run_mode.dart';
import '../core/roguelite/starter_decks.dart';
import '../core/scoring/combo_window.dart';
import 'run_state.dart';
import 'run_transitions.dart';

/// Builds a brand-new Quick Play run: the pre-equipped 5-joker loadout, a
/// 4-piece tray, 10 trays and 6 discards, straight onto the board (status
/// `playing`, no Blind Select).
abstract final class QuickPlayStart {
  static ({RunState state, BlockBag bag}) create(int seed) {
    final deck = StarterDecks.quickPlay;
    const mode = RunMode.quickPlay;
    final bag = BlockBag(
      seed,
      catalog: deck.pool,
      palette: deck.colors,
      traySize: mode.traySize,
      adaptive: mode.adaptiveDealing,
    );
    final state = RunTransitions.beginBlind(
      RunState(
        seed: seed,
        deckId: deck.id,
        mode: mode,
        grid: GridMatrix(),
        tray: bag.drawTray(),
        combo: const ComboWindow(),
        jokers: QuickPlay.loadout(),
        ante: 1,
        blind: BlindType.small,
        score: 0,
        traysRemaining: deck.traysPerBlind,
        discards: deck.discardsPerBlind,
        gold: 0,
      ),
    );
    return (state: state, bag: bag);
  }
}
