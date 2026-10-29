import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _seedFor(BossBlind boss, int ante) => List.generate(
  2000,
  (i) => i,
).firstWhere((s) => BossRegistry.pick(ante, s) == boss);

void main() {
  group('Boss Blinds in a run', () {
    RunState atBoss(int seed, {int ante = 1}) {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(runProvider.notifier)..newRun(seed);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              ante: ante,
              blind: BlindType.big,
              status: RunStatus.shopping,
            ),
      );
      n.leaveShop();
      return c.read(runProvider);
    }

    test('entering the Boss blind picks a boss, shown with its own name', () {
      final s = atBoss(5);
      expect(s.blind, BlindType.boss);
      expect(s.boss, isNotNull);
      expect(s.boss!.finisher, isFalse);
    });

    test('The Needle gives 2 trays; The Water gives 0 discards', () {
      expect(atBoss(_seedFor(BossRegistry.needle, 1)).traysRemaining, 2);
      expect(atBoss(_seedFor(BossRegistry.water, 1)).discards, 0);
    });

    test('The Wall targets 4x the ante base', () {
      final s = atBoss(_seedFor(BossRegistry.wall, 1));
      expect(s.target, 1200);
    });

    test('Ante 8 Boss is Violet Vessel with the 100,000 Finisher target', () {
      final s = atBoss(3, ante: 8);
      expect(s.boss, BossRegistry.violetVessel);
      expect(s.target, 100000);
    });

    test('The Tooth takes \$1 per clearing placement', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(runProvider.notifier)..newRun(1);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: GridMatrix.fromAscii(['XXXXXXX.']),
              tray: [PolyominoCatalog.byId('dot'), null, null],
              boss: BossRegistry.tooth,
              blind: BlindType.boss,
              gold: 6,
            ),
      );
      n.placePiece(0, 0, 7);
      expect(c.read(runProvider).gold, 5);
    });

    test('The Eye blanks a repeated clear type but the lines still clear', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(runProvider.notifier)..newRun(1);
      final dot = PolyominoCatalog.byId('dot');
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: GridMatrix.fromAscii(['XXXXXXX.', 'XXXXXXX.'])
                ..setCell(5, 5, GridCell.plain),
              tray: [dot, dot, null],
              boss: BossRegistry.eye,
              blind: BlindType.boss,
            ),
      );
      n.placePiece(0, 0, 7);
      final first = c.read(runProvider).score;
      expect(first, greaterThan(0));
      expect(c.read(runProvider).archetypesThisBlind, [ClearArchetype.single]);
      n.placePiece(1, 1, 7);
      expect(c.read(runProvider).score, first, reason: 'repeat scores 0');
      expect(c.read(runProvider).lastScore!.blockedByBoss, isTrue);
      expect(c.read(runProvider).grid.isOccupied(1, 0), isFalse);
    });
  });
}
