import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(int seed) {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(seed);
  return c;
}

void main() {
  test('running out of trays below target loses the run', () {
    final c = _container(8);
    final n = c.read(runProvider.notifier);
    final dot = PolyominoCatalog.byId('dot');
    n.debugSet(
      c.read(runProvider).copyWith(tray: [dot, null, null], traysRemaining: 1),
    );
    n.placePiece(0, 4, 4);
    expect(c.read(runProvider).status, RunStatus.lost);
  });

  test(
    'reaching the target clears the blind; cash out then shop then next blind',
    () {
      final c = _container(9);
      final n = c.read(runProvider.notifier);
      final dot = PolyominoCatalog.byId('dot');
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: GridMatrix.fromAscii(['XXXXXXX.']),
              tray: [dot, null, null],
              score: 299,
            ),
      );
      n.placePiece(0, 0, 7);
      expect(c.read(runProvider).status, RunStatus.blindCleared);
      final gold = c.read(runProvider).gold;
      n.collectCashOut();
      expect(c.read(runProvider).status, RunStatus.shopping);
      expect(c.read(runProvider).gold, greaterThan(gold));
      n.leaveShop();
      final s = c.read(runProvider);
      expect(
        [s.status, s.blind, s.score],
        [RunStatus.playing, BlindType.big, 0],
      );
      expect(s.discards, RunState.discardsPerBlind);
    },
  );

  test('board persists to Big/Boss and resets after the Boss; ante +1', () {
    final c = _container(10);
    final n = c.read(runProvider.notifier);
    final base = c.read(runProvider);
    final grid = GridMatrix.fromAscii(['X..']);
    n.debugSet(base.copyWith(grid: grid, status: RunStatus.blindCleared));
    n.collectCashOut();
    n.leaveShop();
    expect(c.read(runProvider).grid.occupiedCount, 1);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(blind: BlindType.boss, status: RunStatus.blindCleared),
    );
    n.collectCashOut();
    n.leaveShop();
    final s = c.read(runProvider);
    expect([s.ante, s.blind], [2, BlindType.small]);
    expect(s.grid.isEmpty, isTrue);
  });

  test('reorderJokers changes Phase 4 order and ignores bad indices', () {
    final c = _container(11);
    final n = c.read(runProvider.notifier);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            jokers: [
              JokerRegistry.byId('joker_plain').joker,
              JokerRegistry.byId('joker_amplifier').joker,
            ],
          ),
    );
    final before = c.read(runProvider).jokers.map((j) => j.id).toList();
    n.reorderJokers(0, 1);
    expect(
      c.read(runProvider).jokers.map((j) => j.id).toList(),
      before.reversed.toList(),
    );
    n.reorderJokers(4, 0);
    n.reorderJokers(0, 99);
    expect(c.read(runProvider).jokers.length, 2);
  });
}
