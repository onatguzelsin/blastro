import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/grid/grid_matrix.dart';
import '../core/polyomino/block_bag.dart';
import '../core/polyomino/polyomino_shape.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/scoring/combo_window.dart';
import 'run_persistence.dart';
import 'run_placement.dart';
import 'run_state.dart';
import 'run_transitions.dart';

final runProvider = NotifierProvider<RunNotifier, RunState>(RunNotifier.new);

/// Bridges the pure Dart engine in `lib/core/` to the UI and auto-saves the
/// run after every placement and shop action.
class RunNotifier extends Notifier<RunState> {
  late BlockBag _bag;

  /// Pieces still in the bag (for the Bag modal).
  List<Polyomino> get bagRemaining => _bag.remaining;

  @override
  RunState build() {
    final saved = ref.read(savedRunProvider);
    if (saved != null) {
      _bag = BlockBag.restore(saved.bag);
      return saved.state;
    }
    return _fresh(DateTime.now().millisecondsSinceEpoch);
  }

  void newRun([int? seed]) {
    _commit(_fresh(seed ?? DateTime.now().millisecondsSinceEpoch));
  }

  RunState _fresh(int seed) {
    _bag = BlockBag(seed);
    return RunTransitions.beginBlind(
      RunState(
        seed: seed,
        grid: GridMatrix(),
        tray: _bag.drawTray(),
        combo: const ComboWindow(),
        jokers: const [],
        ante: 1,
        blind: BlindType.small,
        score: 0,
        traysRemaining: RunState.traysPerBlind,
        discards: RunState.discardsPerBlind,
        gold: RunState.startingGold,
      ),
    );
  }

  /// Sets the state, then saves (or deletes the save if the run is lost).
  void _commit(RunState next) {
    state = next;
    saveNow();
  }

  /// Writes the active run now (also called on `AppLifecycleState.paused`).
  void saveNow() {
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
    final tray = [for (final p in s.tray) p == null ? null : _bag.draw()];
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

  /// Leaves the shop for the next blind. The board persists across blinds
  /// and only resets after a Boss Blind falls.
  void leaveShop() {
    final s = state;
    if (s.status != RunStatus.shopping) return;
    final bossDown = s.blind == BlindType.boss;
    final nextBlind = switch (s.blind) {
      BlindType.small => BlindType.big,
      BlindType.big => BlindType.boss,
      BlindType.boss => BlindType.small,
    };
    final next = RunTransitions.beginBlind(
      s.copyWith(
        grid: bossDown ? GridMatrix() : null,
        ante: bossDown ? min(s.ante + 1, AnteScaling.lastEndlessAnte) : null,
        blind: nextBlind,
        status: RunStatus.playing,
        clearShop: true,
        tray: s.unplaced.isEmpty ? _bag.drawTray() : null,
      ),
    );
    _commit(RunPlacement.settle(next, _bag));
  }

  @visibleForTesting
  void debugSet(RunState value) => state = value;
}
