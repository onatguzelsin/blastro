import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:blastro/core/scoring/score_preview.dart';
import 'package:flutter_test/flutter_test.dart';

final _dot = PolyominoCatalog.byId('dot');

/// Row [row] filled except column 7, plus a spare cell so it isn't a sweep.
GridMatrix _almostRow({int row = 0}) {
  final g = GridMatrix();
  for (var c = 0; c < 7; c++) {
    g.setCell(row, c, GridCell.plain);
  }
  g.setCell(5, 5, GridCell.plain);
  return g;
}

PlacementPreview? _sim(
  GridMatrix grid, {
  int row = 0,
  int col = 7,
  ComboWindow combo = const ComboWindow(),
  List<String> jokers = const [],
  BossBlind? boss,
  List<ClearArchetype> used = const [],
  int seed = 1,
}) => simulatePlacementPreview(
  grid: grid,
  piece: _dot,
  row: row,
  col: col,
  combo: combo,
  rngSeed: seed,
  jokers: [for (final id in jokers) JokerRegistry.byId(id).joker],
  boss: boss,
  usedArchetypes: used,
);

void main() {
  group('never mutates anything', () {
    test('the grid is untouched, before and after the clear', () {
      final grid = _almostRow();
      final before = grid.toJson();
      final sim = _sim(grid)!;
      expect(grid.toJson(), before);
      expect(grid.isOccupied(0, 7), isFalse, reason: 'piece not placed');
      expect(sim.placed.isOccupied(0, 7), isTrue);
      expect(sim.after.isOccupied(0, 0), isFalse, reason: 'row cleared');
      expect(identical(sim.placed, grid), isFalse);
      expect(identical(sim.after, sim.placed), isFalse);
    });

    test('the Block Bag state is identical before and after', () {
      final bag = BlockBag(42);
      final tray = bag.drawTray();
      final snapshot = bag.snapshot().toJson();
      final remaining = bag.remaining.map((p) => p.id).toList();
      for (var i = 0; i < 25; i++) {
        simulatePlacementPreview(
          grid: GridMatrix(),
          piece: tray[i % 3],
          row: i % 6,
          col: i % 5,
          combo: const ComboWindow(),
          rngSeed: i,
        );
      }
      expect(bag.snapshot().toJson(), snapshot);
      expect(bag.remaining.map((p) => p.id).toList(), remaining);
      // And the next real deal is unaffected: same as an untouched bag.
      final fresh = BlockBag(42)..drawTray();
      expect(
        bag.drawTray().map((p) => p.id),
        fresh.drawTray().map((p) => p.id),
      );
    });

    test('the piece, combo window and jokers are untouched', () {
      final cellsBefore = List.of(_dot.cells);
      const combo = ComboWindow(streak: 2, missesInARow: 1);
      final jokers = [JokerRegistry.byId('joker_plain').joker];
      simulatePlacementPreview(
        grid: _almostRow(),
        piece: _dot,
        row: 0,
        col: 7,
        combo: combo,
        rngSeed: 3,
        jokers: jokers,
      );
      expect(_dot.cells, cellsBefore);
      expect([combo.streak, combo.missesInARow], [2, 1]);
      expect(jokers.length, 1);
    });

    test('an illegal placement does nothing and returns null', () {
      final grid = _almostRow();
      final before = grid.toJson();
      expect(_sim(grid, row: 0, col: 0), isNull, reason: 'overlap');
      expect(_sim(grid, row: 8, col: 0), isNull, reason: 'off board');
      expect(_sim(grid, row: 0, col: -1), isNull);
      expect(grid.toJson(), before);
    });
  });

  group('consumes no RNG', () {
    GridMatrix luckyBoard() => _almostRow()
      ..setCell(0, 3, const GridCell(enhancement: CellEnhancement.lucky))
      ..setCell(0, 4, const GridCell(enhancement: CellEnhancement.lucky))
      ..setCell(0, 5, const GridCell(enhancement: CellEnhancement.lucky));

    test('repeated calls with the same seed give the same Lucky outcome', () {
      for (var seed = 0; seed < 20; seed++) {
        final a = _sim(luckyBoard(), seed: seed)!;
        final b = _sim(luckyBoard(), seed: seed)!;
        expect(a.score, b.score, reason: 'seed $seed');
        expect(
          a.result.events.map((e) => e.label),
          b.result.events.map((e) => e.label),
        );
      }
    });

    test('Lucky really varies with the seed (so the above is meaningful)', () {
      final scores = {
        for (var seed = 0; seed < 40; seed++)
          _sim(luckyBoard(), seed: seed)!.score,
      };
      expect(scores.length, greaterThan(1));
    });

    test(
      'previewing between two identical calls does not change the result',
      () {
        final first = _sim(luckyBoard(), seed: 7)!.score;
        for (var i = 0; i < 10; i++) {
          _sim(luckyBoard(), seed: 100 + i);
        }
        expect(_sim(luckyBoard(), seed: 7)!.score, first);
      },
    );
  });
}
