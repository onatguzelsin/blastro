import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_preview.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container([RunPersistence? store]) {
  final c = ProviderContainer(
    overrides: [runPersistenceProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

/// A run in the shop after beating [blind] of [ante], holding a partial tray
/// and an enhanced cell on the board.
RunNotifier _inShop(
  ProviderContainer c, {
  BlindType blind = BlindType.small,
  int ante = 1,
}) {
  final n = c.read(runProvider.notifier)..newRun(31);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          status: RunStatus.shopping,
          blind: blind,
          ante: ante,
          grid: GridMatrix.fromAscii(['XX', 'X'])
            ..setCell(4, 4, const GridCell(enhancement: CellEnhancement.steel)),
          tray: [PolyominoCatalog.byId('dot'), null, null],
          skipped: [BlindType.small],
        ),
  );
  return n;
}

void main() {
  group('Skip Blind', () {
    RunNotifier hub(ProviderContainer c, BlindType blind) {
      final n = c.read(runProvider.notifier)..startRun(8);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              blind: blind,
              grid: GridMatrix.fromAscii(['XXX']),
              tray: [PolyominoCatalog.byId('plus'), null, null],
              gold: 17,
            ),
      );
      return n;
    }

    test('Small and Big can be skipped: next blind, no reward, no shop', () {
      final c = _container();
      final n = hub(c, BlindType.small);
      n.skipBlind();
      var s = c.read(runProvider);
      expect(
        [s.status, s.blind, s.skipped],
        [
          RunStatus.blindSelect,
          BlindType.big,
          [BlindType.small],
        ],
      );
      expect(s.gold, 17, reason: 'no reward');
      expect(s.shop, isNull);
      n.skipBlind();
      s = c.read(runProvider);
      expect(
        [s.blind, s.skipped],
        [
          BlindType.boss,
          [BlindType.small, BlindType.big],
        ],
      );
    });

    test('the board and tray are left untouched', () {
      final c = _container();
      final n = hub(c, BlindType.small);
      final grid = c.read(runProvider).grid.toJson();
      n.skipBlind();
      expect(c.read(runProvider).grid.toJson(), grid);
      expect(c.read(runProvider).tray[0]!.id, 'plus');
      expect(c.read(runProvider).tray[1], isNull);
    });

    test('the Boss cannot be skipped', () {
      final c = _container();
      final n = hub(c, BlindType.boss);
      n.skipBlind();
      final s = c.read(runProvider);
      expect(
        [s.blind, s.skipped, s.status],
        [BlindType.boss, isEmpty, RunStatus.blindSelect],
      );
    });

    test('skipping is only possible on the Blind Select screen', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(3);
      n.skipBlind();
      expect(c.read(runProvider).skipped, isEmpty);
    });

    test('the hub shows skipped blinds as skipped', () {
      final c = _container();
      hub(c, BlindType.small).skipBlind();
      final s = c.read(runProvider);
      final cards = BlindPreviews.forAnte(
        ante: s.ante,
        seed: s.seed,
        current: s.blind,
        skipped: s.skipped.toSet(),
      );
      expect(cards.map((p) => p.status), [
        BlindCardStatus.skipped,
        BlindCardStatus.current,
        BlindCardStatus.locked,
      ]);
    });
  });

  group('Boss on the hub matches the Boss you then face', () {
    test('preview boss equals the active boss after Play Blind', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startRun(77);
      n.debugSet(c.read(runProvider).copyWith(blind: BlindType.boss, ante: 4));
      final s = c.read(runProvider);
      final preview = BlindPreviews.forAnte(
        ante: s.ante,
        seed: s.seed,
        current: s.blind,
      )[2].boss;
      n.playBlind();
      expect(c.read(runProvider).boss, preview);
      expect(
        c.read(runProvider).target,
        AnteScaling.targetFor(
          4,
          BlindType.boss,
          bossMultiplier: preview!.targetMultiplier,
        ),
      );
    });

    test('entering the hub clears the previous boss banner', () {
      final c = _container();
      final n = _inShop(c, blind: BlindType.boss);
      n.debugSet(c.read(runProvider).copyWith(boss: BossRegistry.wall));
      n.leaveShop();
      expect(c.read(runProvider).boss, isNull);
    });
  });
}
