import 'package:blastro/core/grid/line_detector.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:flutter_test/flutter_test.dart';

ClearArchetype? _classify(
  List<int> rows,
  List<int> cols, {
  bool empty = false,
}) => ClearArchetypes.classify(
  LineClears(rows: rows, cols: cols),
  boardEmptyAfter: empty,
);

void main() {
  group('ClearArchetypes.classify', () {
    test('all 10 archetypes', () {
      expect(_classify([], []), isNull);
      expect(_classify([0], []), ClearArchetype.single);
      expect(_classify([], [3]), ClearArchetype.single);
      expect(_classify([0, 1], []), ClearArchetype.parallelDouble);
      expect(_classify([], [2, 5]), ClearArchetype.parallelDouble);
      expect(_classify([0], [0]), ClearArchetype.crossClear);
      expect(_classify([0, 1, 2], []), ClearArchetype.triple);
      expect(_classify([0, 1], [4]), ClearArchetype.triple);
      expect(_classify([0, 1], [0, 1]), ClearArchetype.doubleCross);
      expect(_classify([0, 1, 2, 3], []), ClearArchetype.quad);
      expect(_classify([0, 1, 2], [0]), ClearArchetype.quad);
      expect(_classify([0, 1, 2], [0, 1]), ClearArchetype.penta);
      expect(_classify([0, 1, 2], [0, 1, 2]), ClearArchetype.zone3x3);
      expect(_classify([0, 1, 2, 3], [0, 1]), ClearArchetype.hexa);
      expect(_classify([0, 1, 2, 3, 4, 5], []), ClearArchetype.hexa);
      expect(_classify([0], [0], empty: true), ClearArchetype.cleanSweep);
    });

    test('empty board without a clear is not a CleanSweep', () {
      expect(_classify([], [], empty: true), isNull);
    });

    test('CleanSweep carries the +360 bonus; table covers every archetype', () {
      expect(ClearArchetypes.allClearBonus, 360);
      for (final a in ClearArchetype.values) {
        expect(ClearArchetypes.base[a], isNotNull, reason: a.name);
      }
      final b = ClearArchetypes.base[ClearArchetype.single]!;
      expect(b.chipsAt(3), b.chips + 2 * b.levelChips);
      expect(b.multAt(3), b.mult + 2 * b.levelMult);
    });
  });

  group('ComboWindow', () {
    test('clearing placements increment the streak', () {
      var w = const ComboWindow();
      w = w.afterPlacement(cleared: true);
      w = w.afterPlacement(cleared: true);
      expect(w.streak, 2);
    });

    test('survives 2 non-clearing setup moves, resets on the 3rd', () {
      var w = const ComboWindow(streak: 4);
      w = w.afterPlacement(cleared: false);
      expect(w.streak, 4);
      w = w.afterPlacement(cleared: false);
      expect(w.streak, 4);
      w = w.afterPlacement(cleared: false);
      expect(w.streak, 0);
      expect(w.missesInARow, 0);
    });

    test('a clear in between restarts the miss count', () {
      var w = const ComboWindow(streak: 1);
      w = w.afterPlacement(cleared: false).afterPlacement(cleared: false);
      w = w.afterPlacement(cleared: true);
      expect(w.streak, 2);
      w = w.afterPlacement(cleared: false).afterPlacement(cleared: false);
      expect(w.streak, 2);
      expect(w.afterPlacement(cleared: false).streak, 0);
    });

    test('JSON round trip', () {
      const w = ComboWindow(streak: 3, missesInARow: 2);
      final r = ComboWindow.fromJson(w.toJson());
      expect([r.streak, r.missesInARow], [3, 2]);
    });
  });
}
