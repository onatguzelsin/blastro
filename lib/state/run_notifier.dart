import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/grid/grid_matrix.dart';
import '../core/polyomino/block_bag.dart';
import '../core/polyomino/polyomino_shape.dart';
import '../core/roguelite/starter_decks.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/scoring/combo_window.dart';
import 'quick_play_records.dart';
import 'quick_play_start.dart';
import 'run_blind_flow.dart';
import 'run_persistence.dart';
import 'run_placement.dart';
import 'run_state.dart';
import 'run_state_codec.dart';
import 'run_transitions.dart';

final runProvider = NotifierProvider<RunNotifier, RunState>(RunNotifier.new);

/// Bridges the pure Dart engine in `lib/core/` to the UI and auto-saves the
/// run after every placement and shop action.
class RunNotifier extends Notifier<RunState> {
  late BlockBag _bag;

  /// False until a run is started or restored, so the placeholder run made
  /// on first read (before the menu is used) is never written to disk.
  bool _active = false;

  /// Pieces still in the bag (for the Bag modal).
  List<Polyomino> get bagRemaining => _bag.remaining;

  @override
  RunState build() {
    final saved = ref.read(savedRunProvider);
    if (saved != null) {
      _restoreBag(saved);
      _active = true;
      return saved.state;
    }
    return _fresh(DateTime.now().millisecondsSinceEpoch);
  }

  void _restoreBag(SavedRun saved) {
    final deck = saved.state.deck;
    final mode = saved.state.mode;
    _bag = BlockBag.restore(
      saved.bag,
      catalog: deck.pool,
      palette: deck.colors,
      traySize: mode.traySize,
      adaptive: mode.adaptiveDealing,
    );
  }

  /// Makes a run loaded from disk the active one (Continue Run, or resuming
  /// Quick Play). Nothing is written: the slot already holds exactly this.
  void resumeRun(SavedRun saved) {
    _restoreBag(saved);
    _active = true;
    state = saved.state;
  }

  /// Quick Play: straight onto the board, no menus, with the pre-equipped
  /// loadout, 10 trays, 6 discards and 4-piece trays. It saves to its OWN
  /// slot, so a normal run on disk is never touched.
  void startQuickPlay([int? seed]) {
    final run = QuickPlayStart.create(_seedOrNow(seed));
    _bag = run.bag;
    _commit(run.state);
  }

  /// A fresh run that starts at the first blind's card (the menu path).
  /// [deck] is the starter deck (Standard if omitted).
  void startRun([int? seed, StarterDeck? deck]) {
    _commit(RunBlindFlow.toHub(_fresh(_seedOrNow(seed), deck)));
  }

  /// A fresh run that starts straight on the board.
  void newRun([int? seed, StarterDeck? deck]) =>
      _commit(_fresh(_seedOrNow(seed), deck));

  int _seedOrNow(int? seed) => seed ?? DateTime.now().millisecondsSinceEpoch;

  RunState _fresh(int seed, [StarterDeck? chosen]) {
    final deck = chosen ?? StarterDecks.standard;
    _bag = BlockBag(seed, catalog: deck.pool, palette: deck.colors);
    return RunTransitions.beginBlind(
      RunState(
        seed: seed,
        deckId: deck.id,
        grid: GridMatrix(),
        tray: _bag.drawTray(),
        combo: const ComboWindow(),
        jokers: const [],
        ante: 1,
        blind: BlindType.small,
        score: 0,
        traysRemaining: deck.traysPerBlind,
        discards: deck.discardsPerBlind,
        gold: RunState.startingGold,
      ),
    );
  }

  /// Sets the state, then saves (or deletes the save if the run is lost).
  void _commit(RunState next) {
    _active = true;
    state = next;
    if (next.mode.isQuickPlay) {
      ref.read(quickPlayBestProvider.notifier).record(next.score);
    }
    saveNow();
  }

  /// Writes the active run now (also called on `AppLifecycleState.paused`).
  void saveNow() {
    if (!_active) return;
    ref.read(runPersistenceProvider)?.save(state, _bag.snapshot());
  }

  /// Places tray [slot] with its top-left on ([row], [col]). Returns false
  /// (state untouched) if the move is not legal.
  bool placePiece(int slot, int row, int col) {
    final next = RunPlacement.place(state, _bag, slot, row, col);
    if (next == null) return false;
    _commit(next);
    return true;
  }

  /// Spends a Discard charge to redraw every unplaced tray piece.
  void discardTray() {
    final s = state;
    if (s.status != RunStatus.playing ||
        s.discards == 0 ||
        s.unplaced.isEmpty) {
      return;
    }
    final tray = [
      for (final p in s.tray) p == null ? null : _bag.draw(board: s.grid),
    ];
    _commit(
      RunPlacement.settle(
        s.copyWith(tray: tray, discards: s.discards - 1),
        _bag,
      ),
    );
  }

  /// Moves a joker. Indices follow `ReorderableListView.onReorderItem`.
  void reorderJokers(int from, int to) {
    final s = state;
    if (from < 0 || from >= s.jokers.length) return;
    final target = to.clamp(0, s.jokers.length - 1);
    final jokers = [...s.jokers];
    jokers.insert(target, jokers.removeAt(from));
    _commit(s.copyWith(jokers: jokers));
  }

  /// After the Victory modal: keep the same run (jokers, bag, cards, gold,
  /// board) and cash out into Endless Mode (Antes 9-39).
  void enterEndless() {
    final s = state;
    if (s.status != RunStatus.victory) return;
    _commit(s.copyWith(endless: true, status: RunStatus.blindCleared));
  }

  void rotateTraySlot(int slot) => _commit(RunTransitions.rotate(state, slot));

  void collectCashOut() => _commit(RunTransitions.collectCashOut(state));

  void buyItem(String itemId) => _commit(RunTransitions.buy(state, itemId));

  void rerollShop() => _commit(RunTransitions.reroll(state));

  void sellJoker(int index) => _commit(RunTransitions.sellJoker(state, index));

  void useConsumable(int index) =>
      _commit(RunTransitions.useConsumable(state, index));

  /// Leaves the shop: applies the blind-transition rule (board persists
  /// unless a Boss fell; full new tray) and shows the next Blind Select.
  void leaveShop() => _commit(RunBlindFlow.enterHub(state, _bag));

  /// "Play Blind" on the Blind Select screen.
  void playBlind() => _commit(RunBlindFlow.play(state, _bag));

  /// "Skip Blind" (Small/Big): no reward, no shop; board and tray stay.
  void skipBlind() => _commit(RunBlindFlow.skip(state));

  @visibleForTesting
  void debugSet(RunState value) => state = value;
}
