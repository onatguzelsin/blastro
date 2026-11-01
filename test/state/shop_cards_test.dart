import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(11);
  return c;
}

/// A run sitting at the cash-out screen.
RunNotifier _cleared(ProviderContainer c, {int gold = 10, int trays = 4}) {
  final n = c.read(runProvider.notifier);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          status: RunStatus.blindCleared,
          gold: gold,
          traysRemaining: trays,
        ),
  );
  return n;
}

RunNotifier _shop(ProviderContainer c, {int gold = 30}) {
  final n = _cleared(c, gold: gold);
  n.collectCashOut();
  n.debugSet(c.read(runProvider).copyWith(gold: gold));
  return n;
}

void main() {
  test('Blueprint card levels its archetype; Chisel edits the board', () {
    final c = _container();
    final n = _shop(c);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            consumables: ['blueprint_quad', 'chisel_steel'],
            grid: GridMatrix.fromAscii(['XXXX']),
          ),
    );
    n.useConsumable(0);
    expect(c.read(runProvider).archetypeLevels[ClearArchetype.quad], 2);
    expect(c.read(runProvider).consumables, ['chisel_steel']);
    n.useConsumable(0);
    final steel = [
      for (var col = 0; col < 4; col++) c.read(runProvider).grid.at(0, col)!,
    ].where((x) => x.enhancement == CellEnhancement.steel);
    expect(steel.length, 2);
    expect(c.read(runProvider).consumables, isEmpty);
  });

  test('a Chisel on an empty board is not consumed', () {
    final c = _container();
    final n = _shop(c);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(consumables: ['chisel_bonus'], grid: GridMatrix()),
    );
    n.useConsumable(0);
    expect(c.read(runProvider).consumables, ['chisel_bonus']);
  });

  test('Extra Tray and Discard Hoarder apply to the next blind', () {
    final c = _container();
    final n = _shop(c);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            jokers: [
              JokerRegistry.byId('joker_extra_tray').joker,
              JokerRegistry.byId('joker_discard_hoarder').joker,
            ],
          ),
    );
    n.leaveShop();
    expect(c.read(runProvider).status, RunStatus.blindSelect);
    n.playBlind();
    final s = c.read(runProvider);
    expect(
      [s.traysRemaining, s.discards],
      [RunState.traysPerBlind + 1, RunState.discardsPerBlind + 1],
    );
    expect(s.shop, isNull);
  });

  test('Gyroscope rotates a tray piece; without it nothing happens', () {
    final c = _container();
    final n = c.read(runProvider.notifier);
    final l = PolyominoCatalog.byId('l_small_0');
    n.debugSet(c.read(runProvider).copyWith(tray: [l, null, null]));
    n.rotateTraySlot(0);
    expect(c.read(runProvider).tray[0]!.cells, l.cells);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(jokers: [JokerRegistry.byId('joker_gyroscope').joker]),
    );
    n.rotateTraySlot(0);
    expect(c.read(runProvider).tray[0]!.cells, isNot(l.cells));
    expect(c.read(runProvider).tray[0]!.id, 'l_small_0');
  });
}
