import 'dart:math';

import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/polyomino/polyomino_shape.dart';
import 'package:blastro/core/roguelite/quick_play_rescue.dart';
import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:flutter_test/flutter_test.dart';

Polyomino _p(String id) => PolyominoCatalog.byId(id);

/// Every row full except one hole in column [r] (row r), so no row clears and
/// no vertical bar fits.
GridMatrix _holeDiagonal() {
  final g = GridMatrix();
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      if (c != r) g.setCell(r, c, GridCell.plain);
    }
  }
  return g;
}

GridMatrix _checker() => GridMatrix.fromAscii([
  for (var r = 0; r < 8; r++)
    List.generate(8, (c) => (r + c) % 2 == 0 ? 'X' : '.').join(),
]);

bool _locked(GridMatrix g, List<Polyomino> pieces) =>
    FitValidator.isLockedOut(g, pieces, discardsRemaining: 0);

void main() {
  test('a locked checkerboard really is locked for big pieces', () {
    expect(_locked(_checker(), [_p('bar2_h'), _p('rect_2x2')]), isTrue);
  });

  group('Rescue', () {
    test('always clears at least the 3 fullest rows', () {
      final g = _checker(); // every row has 4 cells
      final r = QuickPlayRescue.rescue(g, [_p('bar2_h')]);
      expect(r.rowsCleared, greaterThanOrEqualTo(QuickPlay.rescueMinRows));
      expect(QuickPlay.rescueMinRows, 3);
    });

    test('fullest rows go first, the bottom of the board before the top', () {
      final g = GridMatrix();
      for (var c = 0; c < 8; c++) {
        g.setCell(0, c, GridCell.plain); // 8
        g.setCell(5, c, GridCell.plain); // 8
      }
      for (var c = 0; c < 6; c++) {
        g.setCell(2, c, GridCell.plain); // 6
      }
      g.setCell(7, 0, GridCell.plain); // 1
      final r = QuickPlayRescue.rescue(g, [_p('rect_3x3')]);
      expect(r.grid.isOccupied(5, 0), isFalse, reason: 'row 5 (full) cleared');
      expect(r.grid.isOccupied(0, 0), isFalse);
      expect(r.grid.isOccupied(2, 0), isFalse);
      expect(r.rowsCleared, 3, reason: 'the 3x3 fits once those are gone');
    });

    test('keeps clearing until something fits', () {
      // After 3 rows a vertical 5-bar still has no home; the 4th row does it.
      final r = QuickPlayRescue.rescue(_holeDiagonal(), [_p('bar5_v')]);
      expect(r.rowsCleared, 4);
      expect(_locked(r.grid, [_p('bar5_v')]), isFalse);
    });

    test('stops at 3 rows when a piece already fits', () {
      final r = QuickPlayRescue.rescue(_holeDiagonal(), [_p('dot')]);
      expect(r.rowsCleared, 3);
    });

    test('never touches the board it was given', () {
      final g = _checker();
      final before = g.toJson();
      QuickPlayRescue.rescue(g, [_p('bar5_h')]);
      expect(g.toJson(), before);
    });

    test('an empty board needs no rescue', () {
      final r = QuickPlayRescue.rescue(GridMatrix(), [_p('rect_3x3')]);
      expect(r.rowsCleared, 0);
      expect(r.grid.isEmpty, isTrue);
    });

    test('allows for rotation when the Gyroscope is in play', () {
      final plain = QuickPlayRescue.rescue(_holeDiagonal(), [_p('bar5_h')]);
      final rotating = QuickPlayRescue.rescue(_holeDiagonal(), [
        _p('bar5_h'),
      ], allowRotation: true);
      expect(rotating.rowsCleared, greaterThanOrEqualTo(3));
      expect(plain.rowsCleared, greaterThanOrEqualTo(3));
    });

    test('fuzz: after a Rescue the board is never locked (200 boards)', () {
      final rng = Random(5);
      for (var i = 0; i < 200; i++) {
        final g = GridMatrix();
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if (rng.nextDouble() < 0.8) g.setCell(r, c, GridCell.plain);
          }
        }
        final pieces = [
          for (var k = 0; k < 4; k++) PolyominoCatalog.all[rng.nextInt(24)],
        ];
        final r = QuickPlayRescue.rescue(g, pieces);
        expect(_locked(r.grid, pieces), isFalse, reason: 'board #$i');
        expect(r.rowsCleared, lessThanOrEqualTo(8));
      }
    });

    test(
      'rescuing a board that is still empty after clearing frees it all',
      () {
        final g = GridMatrix.fromAscii(List.filled(8, 'XXXXXXXX'));
        final r = QuickPlayRescue.rescue(g, [_p('rect_3x3')]);
        expect(r.rowsCleared, 3);
        expect(_locked(r.grid, [_p('rect_3x3')]), isFalse);
      },
    );
  });
}
