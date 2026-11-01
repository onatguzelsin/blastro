import 'dart:convert';

import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_state_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RunPersistence> _store([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return RunPersistence(await SharedPreferences.getInstance());
}

ProviderContainer _container(RunPersistence? store, {SavedRun? saved}) {
  final c = ProviderContainer(
    overrides: [
      runPersistenceProvider.overrideWithValue(store),
      savedRunProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('codec round trip keeps the whole run', () async {
    final store = await _store();
    final c = _container(store);
    final n = c.read(runProvider.notifier)..newRun(77);
    final grid = GridMatrix.fromAscii(['XX', 'X'])
      ..setCell(
        0,
        1,
        const GridCell(
          enhancement: CellEnhancement.steel,
          edition: CellEdition.foil,
          seal: CellSeal.red,
        ),
      );
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            grid: grid,
            jokers: [
              JokerRegistry.byId('joker_cornerstone').joker,
              JokerRegistry.byId('joker_blueprint').joker,
            ],
            consumables: ['chisel_holo'],
            archetypeLevels: {ClearArchetype.quad: 3},
            archetypesThisBlind: [ClearArchetype.single],
            ante: 3,
            blind: BlindType.boss,
            boss: BossRegistry.flint,
            gold: 42,
            score: 1234,
            tray: [
              PolyominoCatalog.byId('l_small_0').nextVariant,
              null,
              PolyominoCatalog.byId('dot'),
            ],
          ),
    );
    n.saveNow();
    final saved = store.load()!;
    final s = saved.state;
    expect(s.jokers.map((j) => j.id), ['joker_cornerstone', 'joker_blueprint']);
    expect(s.consumables, ['chisel_holo']);
    expect(s.archetypeLevels, {ClearArchetype.quad: 3});
    expect(
      [s.ante, s.blind, s.boss, s.gold, s.score],
      [3, BlindType.boss, BossRegistry.flint, 42, 1234],
    );
    final cell = s.grid.at(0, 1)!;
    expect(
      [cell.enhancement, cell.edition, cell.seal],
      [CellEnhancement.steel, CellEdition.foil, CellSeal.red],
    );
    expect(
      s.tray[0]!.cells,
      PolyominoCatalog.byId('l_small_0').nextVariant.cells,
      reason: 'rotated piece survives',
    );
    expect(s.tray[1], isNull);
    expect(s.target, 4000, reason: 'ante 3 base 2000 x boss 2');
    expect(
      jsonEncode(RunStateCodec.encode(s, saved.bag)),
      jsonEncode(RunStateCodec.encode(c.read(runProvider), saved.bag)),
    );
  });

  test('a restored run deals the same trays as the original', () async {
    final store = await _store();
    final a = _container(store);
    final na = a.read(runProvider.notifier)..newRun(5);
    final first = a.read(runProvider).tray[0]!;
    na.placePiece(0, 0, 0);
    final b = _container(null, saved: store.load());
    final nb = b.read(runProvider.notifier);
    expect(b.read(runProvider).tray[0], isNull);
    expect(b.read(runProvider).grid.occupiedCount, first.cellCount);
    for (var slot = 1; slot < 3; slot++) {
      final at = FitValidator.placements(
        a.read(runProvider).grid,
        a.read(runProvider).tray[slot]!,
      ).first;
      expect(na.placePiece(slot, at.row, at.col), isTrue);
      expect(nb.placePiece(slot, at.row, at.col), isTrue);
    }
    // Both runs just finished a tray and drew the next one from the bag.
    expect(
      b.read(runProvider).tray.map((p) => p?.id),
      a.read(runProvider).tray.map((p) => p?.id),
    );
    expect(b.read(runProvider).tray.whereType<Object>().length, 3);
    expect(
      b.read(runProvider).grid.toJson(),
      a.read(runProvider).grid.toJson(),
    );
  });

  test('auto-saves after a placement', () async {
    final store = await _store();
    final prefs = await SharedPreferences.getInstance();
    final c = _container(store);
    final n = c.read(runProvider.notifier)..newRun(3);
    await prefs.remove(RunPersistence.key);
    expect(store.load(), isNull);
    expect(n.placePiece(0, 0, 0), isTrue);
    expect(prefs.containsKey(RunPersistence.key), isTrue);
    expect(store.load()!.state.placements, 1);
  });

  test('auto-saves after shop actions', () async {
    final store = await _store();
    final c = _container(store);
    final n = c.read(runProvider.notifier)..newRun(4);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            status: RunStatus.blindCleared,
            gold: 50,
            traysRemaining: 3,
          ),
    );
    n.collectCashOut();
    expect(store.load()!.state.status, RunStatus.shopping);
    final item = c.read(runProvider).shop!.stock.first;
    n.buyItem(item.id);
    final saved = store.load()!.state;
    expect(saved.gold, c.read(runProvider).gold);
    expect(saved.shop!.stock.length, 4);
    n.rerollShop();
    expect(store.load()!.state.shop!.rerolls, 1);
    n.leaveShop();
    expect(store.load()!.state.status, RunStatus.blindSelect);
    n.playBlind();
    expect(store.load()!.state.status, RunStatus.playing);
  });
}
