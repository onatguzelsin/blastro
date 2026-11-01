import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A run one dot away from clearing [blind] of [ante] on its last point.
ProviderContainer _almostThere(
  int ante,
  BlindType blind, {
  RunPersistence? store,
  bool endless = false,
}) {
  final c = ProviderContainer(
    overrides: [runPersistenceProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(21);
  final base = c.read(runProvider);
  n.debugSet(
    base.copyWith(
      ante: ante,
      blind: blind,
      endless: endless,
      grid: GridMatrix.fromAscii(['XXXXXXX.'])..setCell(5, 5, GridCell.plain),
      tray: [PolyominoCatalog.byId('dot'), null, null],
      jokers: [
        JokerRegistry.byId('joker_plain').joker,
        JokerRegistry.byId('joker_amplifier').joker,
      ],
      consumables: ['blueprint_quad'],
      gold: 37,
      score: AnteScaling.blindTarget(ante, blind) - 1,
    ),
  );
  return c;
}

void main() {
  test('beating the Ante 8 Finisher (100,000) ends in victory', () {
    final c = _almostThere(8, BlindType.boss);
    expect(c.read(runProvider).target, 100000);
    c.read(runProvider.notifier).placePiece(0, 0, 7);
    expect(c.read(runProvider).status, RunStatus.victory);
    expect(c.read(runProvider).endless, isFalse);
  });

  test('Ante 8 Small and Big blinds clear normally, not victory', () {
    for (final blind in [BlindType.small, BlindType.big]) {
      final c = _almostThere(8, blind);
      c.read(runProvider.notifier).placePiece(0, 0, 7);
      expect(c.read(runProvider).status, RunStatus.blindCleared);
    }
  });

  test('earlier Boss Blinds are not victory', () {
    final c = _almostThere(7, BlindType.boss);
    c.read(runProvider.notifier).placePiece(0, 0, 7);
    expect(c.read(runProvider).status, RunStatus.blindCleared);
  });

  test('Endless: later Finishers (Ante 16) clear without a second victory', () {
    final c = _almostThere(16, BlindType.boss, endless: true);
    c.read(runProvider.notifier).placePiece(0, 0, 7);
    expect(c.read(runProvider).status, RunStatus.blindCleared);
  });

  test(
    'enterEndless keeps jokers, tray, bag, cards, gold, board and levels',
    () {
      final c = _almostThere(8, BlindType.boss);
      final n = c.read(runProvider.notifier);
      n.placePiece(0, 0, 7);
      final before = c.read(runProvider);
      final bag = n.bagRemaining.map((p) => p.id).toList();

      n.enterEndless();
      final s = c.read(runProvider);
      expect([s.status, s.endless], [RunStatus.blindCleared, true]);
      expect(s.jokers.map((j) => j.id), before.jokers.map((j) => j.id));
      expect(s.consumables, before.consumables);
      expect(s.gold, before.gold);
      expect(s.grid.toJson(), before.grid.toJson());
      expect(s.archetypeLevels, before.archetypeLevels);
      expect(s.tray.map((p) => p?.id), before.tray.map((p) => p?.id));
      expect(n.bagRemaining.map((p) => p.id).toList(), bag);
    },
  );

  test('cash out, shop and leaving lands on Ante 9 Small Blind', () {
    final c = _almostThere(8, BlindType.boss);
    final n = c.read(runProvider.notifier)..placePiece(0, 0, 7);
    n.enterEndless();
    final gold = c.read(runProvider).gold;
    n.collectCashOut();
    expect(c.read(runProvider).status, RunStatus.shopping);
    expect(c.read(runProvider).gold, greaterThan(gold));
    n.leaveShop();
    expect(c.read(runProvider).status, RunStatus.blindSelect);
    n.playBlind();
    final s = c.read(runProvider);
    expect(
      [s.ante, s.blind, s.status],
      [9, BlindType.small, RunStatus.playing],
    );
    expect(s.endless, isTrue);
    expect(s.target, AnteScaling.blindTarget(9, BlindType.small));
    expect(s.grid.isEmpty, isTrue, reason: 'board resets after a Boss');
    expect(s.jokers.length, 2);
  });

  test('enterEndless only works from victory', () {
    final c = _almostThere(8, BlindType.small);
    c.read(runProvider.notifier).enterEndless();
    expect(c.read(runProvider).endless, isFalse);
  });

  test('victory and endless survive a save and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RunPersistence(await SharedPreferences.getInstance());
    final c = _almostThere(8, BlindType.boss, store: store);
    final n = c.read(runProvider.notifier)..placePiece(0, 0, 7);
    expect(store.load()!.state.status, RunStatus.victory);
    n.enterEndless();
    final saved = store.load()!.state;
    expect([saved.status, saved.endless], [RunStatus.blindCleared, true]);
  });

  test('a save without the endless field still loads (older saves)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = RunPersistence(prefs);
    final c = _almostThere(2, BlindType.small, store: store);
    c.read(runProvider.notifier).saveNow();
    final raw = prefs.getString(RunPersistence.key)!;
    await prefs.setString(
      RunPersistence.key,
      raw.replaceAll(RegExp(r'"endless":(true|false),?'), ''),
    );
    expect(store.load()!.state.endless, isFalse);
  });
}
