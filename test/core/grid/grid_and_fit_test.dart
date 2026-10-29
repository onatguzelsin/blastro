import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/grid/line_detector.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dot = PolyominoCatalog.byId('dot');
  final bar3 = PolyominoCatalog.byId('bar3_h');

  group('GridMatrix placement', () {
    test('place stamps cells; overlap and bounds throw without writing', () {
      final g = GridMatrix()..place(bar3, 0, 0);
      expect(g.occupiedCount, 3);
      expect(() => g.place(bar3, 0, 2), throwsStateError);
      expect(() => g.place(bar3, 0, 6), throwsRangeError);
      expect(g.occupiedCount, 3);
    });

    test('FitValidator.canPlace', () {
      final g = GridMatrix()..place(dot, 3, 3);
      expect(FitValidator.canPlace(g, bar3, 3, 1), isFalse);
      expect(FitValidator.canPlace(g, bar3, 3, 4), isTrue);
      expect(FitValidator.canPlace(g, bar3, 0, 6), isFalse);
      expect(FitValidator.canPlace(g, dot, -1, 0), isFalse);
    });

    test('placements enumerates anchors', () {
      expect(FitValidator.placements(GridMatrix(), bar3).length, 8 * 6);
    });
  });

  group('LineDetector', () {
    test('detects a single row and a single column', () {
      expect(LineDetector.detect(GridMatrix.fromAscii(['XXXXXXXX'])).rows, [0]);
      final full = GridMatrix.fromAscii(List.filled(8, 'XXXXXXXX'));
      final lines = LineDetector.detect(full);
      expect(lines.rows, [0, 1, 2, 3, 4, 5, 6, 7]); // fully filled board
      expect(lines.cols.length, 8);
    });

    test('simultaneous row + column clear is reported together', () {
      final g = GridMatrix.fromAscii([
        'XXXXXXXX',
        'X.......',
        'X.......',
        'X.......',
        'X.......',
        'X.......',
        'X.......',
        'X.......',
      ]);
      final lines = LineDetector.detect(g);
      expect(lines.rows, [0]);
      expect(lines.cols, [0]);
      expect(lines.lineCount, 2);
    });

    test('clearLines empties rows and cols at once', () {
      final g = GridMatrix.fromAscii(['XXXXXXXX', 'X.......', 'X.......'])
        ..setCell(5, 5, GridMatrix.fromAscii(['X']).at(0, 0));
      g.clearLines(rows: [0], cols: [0]);
      expect(g.occupiedCount, 1);
      expect(g.isOccupied(5, 5), isTrue);
    });

    test('no clears on a partial board', () {
      expect(
        LineDetector.detect(GridMatrix.fromAscii(['XXXXXXX.'])).isEmpty,
        isTrue,
      );
    });
  });

  group('Grid Lockout', () {
    // Checkerboard: no 2-in-a-row anywhere, but dots still fit if any empty.
    final checker = GridMatrix.fromAscii([
      for (var r = 0; r < 8; r++)
        List.generate(8, (c) => (r + c) % 2 == 0 ? 'X' : '.').join(),
    ]);
    final bar2 = PolyominoCatalog.byId('bar2_h');
    final bar2v = PolyominoCatalog.byId('bar2_v');

    test('locked out when nothing fits and no discards', () {
      expect(
        FitValidator.isLockedOut(checker, [
          bar2,
          bar2v,
          bar3,
        ], discardsRemaining: 0),
        isTrue,
      );
    });

    test('a discard charge prevents lockout', () {
      expect(
        FitValidator.isLockedOut(checker, [bar2, bar3], discardsRemaining: 1),
        isFalse,
      );
    });

    test('one fitting piece prevents lockout', () {
      expect(
        FitValidator.isLockedOut(checker, [bar2, dot], discardsRemaining: 0),
        isFalse,
      );
    });

    test('rotation can rescue a lockout', () {
      final g = GridMatrix.fromAscii([
        'XXXXXXXX',
        '.XXXXXXX',
        '.XXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
      ]);
      expect(FitValidator.isLockedOut(g, [bar2], discardsRemaining: 0), isTrue);
      expect(
        FitValidator.isLockedOut(
          g,
          [bar2],
          discardsRemaining: 0,
          allowRotation: true,
        ),
        isFalse,
        reason: 'the vertical gap at (1,0),(2,0) fits a rotated 2-bar',
      );
    });

    test('empty tray is never a lockout', () {
      expect(
        FitValidator.isLockedOut(checker, [], discardsRemaining: 0),
        isFalse,
      );
    });
  });
}
