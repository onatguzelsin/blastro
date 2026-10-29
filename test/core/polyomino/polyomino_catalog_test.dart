import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/polyomino/polyomino_shape.dart';
import 'package:flutter_test/flutter_test.dart';

bool _connected(Polyomino p) {
  final todo = p.cells.toSet();
  final stack = [todo.first];
  final seen = <CellOffset>{};
  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    if (!todo.contains(cur) || !seen.add(cur)) continue;
    stack.addAll([
      CellOffset(cur.row + 1, cur.col),
      CellOffset(cur.row - 1, cur.col),
      CellOffset(cur.row, cur.col + 1),
      CellOffset(cur.row, cur.col - 1),
    ]);
  }
  return seen.length == todo.length;
}

void main() {
  group('PolyominoCatalog', () {
    test('has exactly 24 unique shapes', () {
      expect(PolyominoCatalog.all.length, 24);
      expect(PolyominoCatalog.all.map((p) => p.id).toSet().length, 24);
      final geometry = PolyominoCatalog.all.map((p) => p.cells.join()).toSet();
      expect(geometry.length, 24, reason: 'no duplicate footprints');
    });

    test('every shape is connected, normalized and tiered 1..4', () {
      for (final p in PolyominoCatalog.all) {
        expect(_connected(p), isTrue, reason: p.id);
        expect(p.cells.map((c) => c.row).reduce((a, b) => a < b ? a : b), 0);
        expect(p.cells.map((c) => c.col).reduce((a, b) => a < b ? a : b), 0);
        expect(p.dangerTier, inInclusiveRange(1, 4));
        expect(p.cellCount, p.cells.length);
      }
    });

    test('cell counts of named shapes', () {
      final n = {for (final p in PolyominoCatalog.all) p.id: p.cellCount};
      expect(n['dot'], 1);
      expect(n['bar5_h'], 5);
      expect(n['rect_3x3'], 9);
      expect(n['l_small_0'], 3);
      expect(n['l_big_0'], 5);
      expect(n['plus'], 5);
      expect(n['tee'], 4);
      expect(n['zig'], 4);
    });

    test('variants are deduplicated', () {
      expect(PolyominoCatalog.byId('dot').variants.length, 1);
      expect(PolyominoCatalog.byId('rect_2x2').variants.length, 1);
      expect(PolyominoCatalog.byId('plus').variants.length, 1);
      expect(PolyominoCatalog.byId('bar3_h').variants.length, 2);
      expect(PolyominoCatalog.byId('l_small_0').variants.length, 4);
      expect(PolyominoCatalog.byId('zig').variants.length, 4); // Z, S, rotated
      expect(
        PolyominoCatalog.byId('zig').variants.first.cells,
        PolyominoCatalog.byId('zig').cells,
      );
    });

    test('unknown id throws', () {
      expect(() => PolyominoCatalog.byId('nope'), throwsArgumentError);
    });
  });

  group('BlockBag', () {
    test('same seed gives identical sequence; different seed differs', () {
      List<String> run(int seed) {
        final bag = BlockBag(seed);
        return [
          for (var i = 0; i < 20; i++) ...bag.drawTray().map((p) => p.id),
        ];
      }

      expect(run(42), run(42));
      expect(run(42), isNot(run(43)));
    });

    test('trays have 3 pieces and a full bag deals every shape once', () {
      final bag = BlockBag(7);
      expect(bag.drawTray().length, 3);
      final ids = <String>[...bag.remaining.map((p) => p.id)];
      expect(ids.length, 21);
      final bag2 = BlockBag(7);
      final dealt = [for (var i = 0; i < 8; i++) ...bag2.drawTray()];
      expect(dealt.map((p) => p.id).toSet().length, 24);
    });

    test('refills when empty', () {
      final bag = BlockBag(1);
      for (var i = 0; i < 30; i++) {
        expect(bag.drawTray().length, 3);
      }
    });

    test('snapshot restore continues identically (incl. JSON)', () {
      final bag = BlockBag(99);
      for (var i = 0; i < 9; i++) {
        bag.drawTray();
      }
      final snap = BlockBagSnapshot.fromJson(bag.snapshot().toJson());
      final restored = BlockBag.restore(snap);
      for (var i = 0; i < 12; i++) {
        expect(
          restored.drawTray().map((p) => p.id),
          bag.drawTray().map((p) => p.id),
        );
      }
    });
  });
}
