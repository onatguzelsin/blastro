import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/score_preview.dart';
import 'package:blastro/state/placement_preview.dart';
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

void main() {
  group('the real placement scores exactly what the preview promised', () {
    for (var seed = 1; seed <= 40; seed++) {
      test('seed $seed', () {
        final c = _container();
        final n = c.read(runProvider.notifier)..newRun(seed);
        final grid = GridMatrix();
        for (var r = 0; r < 8; r++) {
          for (var col = 0; col < 8; col++) {
            if ((r * 8 + col + seed) % 5 != 0) {
              grid.setCell(
                r,
                col,
                GridCell(
                  enhancement: CellEnhancement.values[(r + col + seed) % 6],
                  edition: CellEdition.values[(r * col + seed) % 4],
                ),
              );
            }
          }
        }
        final dot = PolyominoCatalog.byId('dot');
        n.debugSet(
          c
              .read(runProvider)
              .copyWith(
                grid: grid,
                tray: [dot, null, null],
                jokers: [
                  for (final d in JokerRegistry.all.skip(seed % 15).take(4))
                    d.joker,
                ],
              ),
        );
        final spots = FitValidator.placements(grid, dot);
        if (spots.isEmpty) return;
        final at = spots[seed % spots.length];
        final s = c.read(runProvider);
        final preview = RunPlacement.preview(s, 0, at.row, at.col)!;
        final promised = preview.score;
        final promisedGrid = preview.after.toJson();
        final promisedCombo = preview.combo.streak;

        n.placePiece(0, at.row, at.col);
        final after = c.read(runProvider);
        expect(after.lastScore!.finalScore, promised);
        expect(after.grid.toJson(), promisedGrid);
        expect(after.combo.streak, promisedCombo);
        expect(after.score, s.score + promised);
      });
    }
  });

  test('previewing never changes the run state or the bag', () {
    final c = _container();
    final n = c.read(runProvider.notifier)..newRun(5);
    final before = c.read(runProvider);
    final bag = n.bagRemaining.map((p) => p.id).toList();
    for (var i = 0; i < 30; i++) {
      RunPlacement.preview(before, i % 3, i % 6, i % 5);
    }
    final after = c.read(runProvider);
    expect(identical(after, before), isTrue);
    expect(after.grid.toJson(), before.grid.toJson());
    expect(after.placements, 0);
    expect(after.scoreSerial, 0);
    expect(n.bagRemaining.map((p) => p.id).toList(), bag);
  });

  test('no preview outside a playing round or from an empty slot', () {
    final c = _container();
    final n = c.read(runProvider.notifier)..newRun(5);
    n.debugSet(c.read(runProvider).copyWith(status: RunStatus.shopping));
    expect(RunPlacement.preview(c.read(runProvider), 0, 0, 0), isNull);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(status: RunStatus.playing, tray: [null, null, null]),
    );
    expect(RunPlacement.preview(c.read(runProvider), 0, 0, 0), isNull);
  });

  group('placementPreviewProvider', () {
    const a = PreviewSummary(
      title: 'SINGLE LINE',
      chips: 90,
      mult: 1,
      score: 90,
    );

    test('starts empty, shows, clears', () {
      final c = _container();
      expect(c.read(placementPreviewProvider), isNull);
      c.read(placementPreviewProvider.notifier).show(a);
      expect(c.read(placementPreviewProvider), a);
      c.read(placementPreviewProvider.notifier).clear();
      expect(c.read(placementPreviewProvider), isNull);
    });

    test('an identical summary does not notify listeners again', () {
      final c = _container();
      var notifications = 0;
      c.listen(placementPreviewProvider, (_, _) => notifications++);
      final n = c.read(placementPreviewProvider.notifier);
      n.show(a);
      n.show(
        const PreviewSummary(
          title: 'SINGLE LINE',
          chips: 90,
          mult: 1,
          score: 90,
        ),
      );
      n.show(a);
      expect(notifications, 1);
      n.show(
        const PreviewSummary(
          title: 'SINGLE LINE',
          chips: 90,
          mult: 2,
          score: 180,
        ),
      );
      expect(notifications, 2);
    });
  });
}
