import 'dart:math';

import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:blastro/core/scoring/score_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fuzz: previews are deterministic and pure over 150 random moves', () {
    final rng = Random(2024);
    final jokerIds = JokerRegistry.all.map((d) => d.id).toList();
    var clearing = 0;
    for (var i = 0; i < 150; i++) {
      final grid = GridMatrix();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (rng.nextDouble() < 0.72) {
            grid.setCell(
              r,
              c,
              GridCell(
                enhancement: CellEnhancement.values[rng.nextInt(6)],
                edition: CellEdition.values[rng.nextInt(4)],
                seal: rng.nextInt(8) == 0 ? CellSeal.red : CellSeal.none,
              ),
            );
          }
        }
      }
      final piece = PolyominoCatalog.all[rng.nextInt(24)];
      final spots = FitValidator.placements(grid, piece);
      if (spots.isEmpty) continue;
      final at = spots[rng.nextInt(spots.length)];
      final jokers = [
        for (final id in jokerIds)
          if (rng.nextInt(5) == 0) JokerRegistry.byId(id).joker,
      ].take(5).toList();
      final combo = ComboWindow(
        streak: rng.nextInt(5),
        missesInARow: rng.nextInt(3),
      );
      final boss = rng.nextBool() ? BossRegistry.all[rng.nextInt(10)] : null;
      final seed = rng.nextInt(1 << 20);
      final before = grid.toJson();

      PlacementPreview? run() => simulatePlacementPreview(
        grid: grid,
        piece: piece,
        row: at.row,
        col: at.col,
        combo: combo,
        rngSeed: seed,
        jokers: jokers,
        boss: boss,
      );
      final a = run()!;
      final b = run()!;
      expect(a.score, b.score, reason: 'deterministic #$i');
      expect(a.chips, b.chips);
      expect(a.mult, b.mult);
      expect(a.after.toJson(), b.after.toJson());
      expect(grid.toJson(), before, reason: 'input untouched #$i');
      if (a.clears) clearing++;
    }
    expect(clearing, greaterThan(20), reason: 'the fuzz must hit real clears');
  });
}
