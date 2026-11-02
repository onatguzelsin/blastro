import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:blastro/state/quick_play_event.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_placement.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

GridMatrix _checker() => GridMatrix.fromAscii([
  for (var r = 0; r < 8; r++)
    List.generate(8, (c) => (r + c) % 2 == 0 ? 'X' : '.').join(),
]);

void main() {
  group('Quick Play has no blinds and no end', () {
    test('a huge score never clears a blind or wins', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              score: 1000000000,
              grid: GridMatrix.fromAscii(['XXXXXXX.']),
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 0, 7);
      expect(c.read(runProvider).status, RunStatus.playing);
    });

    test('Second Wind: running out of trays gives a fresh batch of 10', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              traysRemaining: 1,
              combo: const ComboWindow(streak: 5),
              grid: GridMatrix(),
              tray: [PolyominoCatalog.byId('dot'), null, null, null],
            ),
      );
      n.placePiece(0, 4, 4);
      final s = c.read(runProvider);
      expect(s.status, RunStatus.playing, reason: 'no game over');
      expect(s.traysRemaining, 10);
      expect(s.quickEvent.windTrays, 10);
      expect(s.quickEvent.callouts(), ['SECOND WIND! +10 TRAYS']);
      expect(s.combo.streak, 0, reason: 'it costs the combo');
      expect(s.unplaced.length, 4, reason: 'and a new 4-piece tray');
    });

    test('no Second Wind while trays remain', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              traysRemaining: 2,
              grid: GridMatrix(),
              tray: [PolyominoCatalog.byId('dot'), null, null, null],
            ),
      );
      n.placePiece(0, 4, 4);
      expect(c.read(runProvider).traysRemaining, 1);
      expect(c.read(runProvider).quickEvent.windTrays, 0);
    });

    test('Rescue: nothing fits and no discards clears the fullest rows', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      final bar = PolyominoCatalog.byId('bar5_h');
      final stuck = c
          .read(runProvider)
          .copyWith(
            grid: _checker(),
            discards: 0,
            combo: const ComboWindow(streak: 4),
            tray: [bar, bar, bar, bar],
          );
      final settled = RunPlacement.settle(stuck, BlockBag(1, traySize: 4));
      expect(settled.status, RunStatus.playing, reason: 'never lost');
      expect(settled.quickEvent.rescuedRows, greaterThanOrEqualTo(3));
      expect(settled.quickEvent.callouts().first, startsWith('RESCUE!'));
      expect(settled.combo.streak, 0, reason: 'it costs the combo');
      expect(settled.discards, 0);
      expect(
        FitValidator.isLockedOut(
          settled.grid,
          settled.unplaced,
          discardsRemaining: 0,
        ),
        isFalse,
      );
      expect(settled.score, stuck.score, reason: 'a Rescue scores nothing');
      expect(
        settled.traysRemaining,
        stuck.traysRemaining,
        reason: 'and refunds nothing',
      );
      n.debugSet(settled);
      expect(c.read(runProvider).status, RunStatus.playing);
    });

    test('with discards left there is no Rescue yet: you may discard', () {
      final c = _container();
      c.read(runProvider.notifier).startQuickPlay(3);
      final bar = PolyominoCatalog.byId('bar5_h');
      final s = c
          .read(runProvider)
          .copyWith(grid: _checker(), discards: 2, tray: [bar, bar, bar, bar]);
      final settled = RunPlacement.settle(s, BlockBag(1, traySize: 4));
      expect(settled.quickEvent.rescuedRows, 0);
      expect(settled.grid.toJson(), s.grid.toJson());
    });

    test('a normal run is still lost when nothing fits (unchanged)', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(3);
      final bar = PolyominoCatalog.byId('bar5_h');
      final stuck = c
          .read(runProvider)
          .copyWith(grid: _checker(), discards: 0, tray: [bar, bar, bar]);
      n.debugSet(RunPlacement.settle(stuck, BlockBag(1)));
      expect(c.read(runProvider).status, RunStatus.lost);
    });

    test('the callout texts', () {
      expect(const QuickPlayEvent(trayRefund: 15).callouts(), ['+15 TRAYS!']);
      expect(const QuickPlayEvent(rescuedRows: 1).callouts(), [
        'RESCUE! 1 row cleared',
      ]);
      expect(const QuickPlayEvent(rescuedRows: 4).callouts(), [
        'RESCUE! 4 rows cleared',
      ]);
      expect(
        const QuickPlayEvent(
          trayRefund: 8,
          windTrays: 10,
          rescuedRows: 3,
        ).callouts().length,
        3,
      );
      expect(QuickPlayEvent.none.isEmpty, isTrue);
      expect(QuickPlayEvent.none.callouts(), isEmpty);
    });
  });

  group('a bot that just plays and plays', () {
    for (final seed in [1, 7, 42, 99, 2024]) {
      test('seed $seed: 2,500 moves and the run never ends', () {
        final c = _container();
        final n = c.read(runProvider.notifier)..startQuickPlay(seed);
        var rescues = 0, winds = 0, refunds = 0, moves = 0;
        var lastEvent = c.read(runProvider).quickEvent;
        while (moves < 2500) {
          final s = c.read(runProvider);
          expect(s.status, RunStatus.playing, reason: 'move $moves');
          expect(s.traysRemaining, greaterThanOrEqualTo(1));
          expect(s.unplaced, isNotEmpty);
          // Place the first piece that fits anywhere.
          var placed = false;
          for (var slot = 0; slot < s.tray.length && !placed; slot++) {
            final p = s.tray[slot];
            if (p == null) continue;
            final spots = FitValidator.placements(s.grid, p);
            if (spots.isEmpty) continue;
            placed = n.placePiece(slot, spots.first.row, spots.first.col);
          }
          if (!placed) {
            expect(
              s.discards,
              greaterThan(0),
              reason: 'stuck without discards',
            );
            n.discardTray();
          }
          final e = c.read(runProvider).quickEvent;
          if (!identical(e, lastEvent)) {
            lastEvent = e;
            if (e.rescuedRows > 0) rescues++;
            if (e.windTrays > 0) winds++;
            if (e.trayRefund > 0) refunds++;
          }
          moves++;
        }
        expect(c.read(runProvider).score, greaterThan(0));
        // The two safety nets really were exercised.
        expect(rescues, greaterThan(0), reason: 'seed $seed rescues');
        expect(rescues + winds + refunds, greaterThan(5));
      });
    }
  });
}
