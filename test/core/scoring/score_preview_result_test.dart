import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
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
  group('what it reports', () {
    test('a non-clearing drop has no archetype and no summary', () {
      final sim = _sim(GridMatrix(), row: 3, col: 3)!;
      expect(sim.clears, isFalse);
      expect(sim.archetype, isNull);
      expect(sim.score, 0);
      expect(sim.summary, isNull);
    });

    test('a single line: title, chips, mult and score', () {
      final sim = _sim(_almostRow())!;
      expect(sim.archetype, ClearArchetype.single);
      expect(sim.summary!.title, 'SINGLE LINE');
      expect([sim.chips, sim.mult], [90, 2], reason: '1 streak adds +1 mult');
      expect(sim.score, 180);
      expect(sim.summary!.score, 180);
    });

    test('uses the combo window: streak and expiry', () {
      const combo = ComboWindow(streak: 2);
      expect(_sim(_almostRow(), combo: combo)!.combo.streak, 3);
      expect(_sim(_almostRow(), combo: combo)!.mult, 1 + 3);
      final nonClear = _sim(
        GridMatrix(),
        row: 3,
        col: 3,
        combo: const ComboWindow(streak: 4, missesInARow: 2),
      )!;
      expect(nonClear.combo.streak, 0, reason: '3rd miss resets');
    });

    test('Streak Saver widens the window in the preview too', () {
      const combo = ComboWindow(streak: 4, missesInARow: 2);
      final saved = _sim(
        GridMatrix(),
        row: 3,
        col: 3,
        combo: combo,
        jokers: ['joker_streak_saver'],
      )!;
      expect(saved.combo.streak, 4);
    });

    test('a Cross Clear', () {
      final g = _almostRow();
      for (var r = 1; r < 8; r++) {
        g.setCell(r, 7, GridCell.plain);
      }
      final sim = _sim(g)!;
      expect(sim.archetype, ClearArchetype.crossClear);
      expect(sim.summary!.title, 'CROSS CLEAR!');
    });

    test('a Clean Sweep includes the +360 bonus', () {
      final g = GridMatrix();
      for (var c = 0; c < 7; c++) {
        g.setCell(0, c, GridCell.plain);
      }
      final sim = _sim(g)!;
      expect(sim.archetype, ClearArchetype.cleanSweep);
      expect(sim.summary!.title, 'CLEAN SWEEP!');
      expect(sim.result.allClearBonus, 360);
      expect(sim.score, greaterThan(360));
    });

    test('jokers are applied in the preview', () {
      final plain = _sim(_almostRow())!;
      final plus4 = _sim(_almostRow(), jokers: ['joker_plain'])!;
      expect(plus4.mult, plain.mult + 4);
    });

    test('a boss that blanks the clear: still named, scores 0, blamed', () {
      final sim = _sim(
        _almostRow(),
        boss: BossRegistry.eye,
        used: [ClearArchetype.single],
      )!;
      expect(sim.archetype, ClearArchetype.single);
      expect(sim.score, 0);
      expect(sim.blockedBy, 'The Eye');
      final s = sim.summary!;
      expect([s.title, s.blockedBy, s.score], ['SINGLE LINE', 'The Eye', 0]);
      expect([s.chips, s.mult], [0, 0]);
    });

    test('the Eye lets a new clear type through', () {
      final sim = _sim(_almostRow(), boss: BossRegistry.eye)!;
      expect(sim.blockedBy, isNull);
      expect(sim.score, greaterThan(0));
    });

    test('summaries compare by value (so repeated hovers are ignored)', () {
      expect(_sim(_almostRow())!.summary, _sim(_almostRow())!.summary);
      expect(
        _sim(_almostRow())!.summary,
        isNot(_sim(_almostRow(), jokers: ['joker_plain'])!.summary),
      );
    });

    test('all 10 clear types have a distinct HUD title', () {
      final titles = ClearArchetype.values.map(previewTitle).toSet();
      expect(titles.length, 10);
      expect(previewTitle(ClearArchetype.single), 'SINGLE LINE');
      expect(previewTitle(ClearArchetype.parallelDouble), 'PARALLEL DOUBLE!');
      expect(previewTitle(ClearArchetype.crossClear), 'CROSS CLEAR!');
    });
  });
}
