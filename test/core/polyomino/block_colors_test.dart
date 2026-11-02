import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _ids(BlockBag bag, int n) => [
  for (var i = 0; i < n; i++) bag.draw().id,
];

Set<BlockColor> _colorsOf(BlockBag bag, int n) => {
  for (var i = 0; i < n; i++) bag.draw().color!,
};

void main() {
  group('dealing colors', () {
    test('the default palette deals all four colors', () {
      expect(_colorsOf(BlockBag(1), 500), BlockColor.values.toSet());
    });

    test('Chromatic palette: ONLY red and blue, and both appear', () {
      const palette = [BlockColor.red, BlockColor.blue];
      final seen = _colorsOf(BlockBag(1, palette: palette), 3000);
      expect(seen, {BlockColor.red, BlockColor.blue});
    });

    test('a one-color palette deals that color every time', () {
      final bag = BlockBag(5, palette: const [BlockColor.green]);
      for (var i = 0; i < 100; i++) {
        expect(bag.draw().color, BlockColor.green);
      }
    });

    test('colors are roughly even across the palette', () {
      final bag = BlockBag(8, palette: const [BlockColor.red, BlockColor.blue]);
      var red = 0;
      for (var i = 0; i < 4000; i++) {
        if (bag.draw().color == BlockColor.red) red++;
      }
      expect(red, inInclusiveRange(1800, 2200));
    });

    test('same seed gives the same colors; another seed differs', () {
      List<BlockColor?> run(int seed) => [
        for (final p in BlockBag(seed).drawTray()) p.color,
        for (final p in BlockBag(seed).drawTray()) p.color,
      ];
      expect(run(4), run(4));
      final many = {for (var s = 0; s < 20; s++) run(s).join()};
      expect(many.length, greaterThan(1));
    });

    test('catalog shapes themselves stay uncolored', () {
      expect(PolyominoCatalog.all.every((p) => p.color == null), isTrue);
    });
  });

  group('colors never disturb the shapes', () {
    test('the same seed deals the same shape order for ANY palette', () {
      final base = _ids(BlockBag(31), 600);
      expect(_ids(BlockBag(31, palette: const [BlockColor.red]), 600), base);
      expect(
        _ids(
          BlockBag(31, palette: const [BlockColor.red, BlockColor.blue]),
          600,
        ),
        base,
      );
    });
  });

  group('saving and restoring', () {
    test('a restored bag continues with the same shapes AND colors', () {
      const palette = [BlockColor.red, BlockColor.blue, BlockColor.green];
      final bag = BlockBag(77, palette: palette);
      for (var i = 0; i < 11; i++) {
        bag.drawTray();
      }
      final snap = BlockBagSnapshot.fromJson(bag.snapshot().toJson());
      final restored = BlockBag.restore(snap, palette: palette);
      for (var i = 0; i < 40; i++) {
        final a = bag.drawTray();
        final b = restored.drawTray();
        expect(b.map((p) => p.id), a.map((p) => p.id));
        expect(b.map((p) => p.color), a.map((p) => p.color));
      }
    });

    test('the snapshot counts the color draws', () {
      final bag = BlockBag(2)..drawTray();
      expect(bag.snapshot().colorDraws, 3);
      expect(bag.snapshot().toJson()['colors'], 3);
    });

    test('an older snapshot without color info still restores', () {
      final bag = BlockBag(2)..drawTray();
      final json = bag.snapshot().toJson()..remove('colors');
      final restored = BlockBag.restore(BlockBagSnapshot.fromJson(json));
      expect(restored.drawTray().length, 3);
    });
  });

  group('a piece keeps its color', () {
    test('withColor makes a recolored copy', () {
      final dot = PolyominoCatalog.byId('dot');
      final red = dot.withColor(BlockColor.red);
      expect(red.color, BlockColor.red);
      expect(red.id, dot.id);
      expect(dot.color, isNull);
    });

    test('rotations and the tap-to-rotate variant keep the color', () {
      final l = PolyominoCatalog.byId('l_small_0').withColor(BlockColor.green);
      for (final v in l.variants) {
        expect(v.color, BlockColor.green);
      }
      expect(l.nextVariant.color, BlockColor.green);
    });
  });

  group('colors on the board', () {
    test('placing a piece copies its color onto every cell', () {
      final grid = GridMatrix();
      final plus = PolyominoCatalog.byId('plus').withColor(BlockColor.yellow);
      grid.place(plus, 2, 2);
      var colored = 0;
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (grid.isOccupied(r, c)) {
            expect(grid.at(r, c)!.color, BlockColor.yellow);
            colored++;
          }
        }
      }
      expect(colored, 5);
    });

    test('an uncolored piece makes uncolored cells', () {
      final grid = GridMatrix()..place(PolyominoCatalog.byId('dot'), 0, 0);
      expect(grid.at(0, 0)!.color, isNull);
    });

    test('an explicit cell template wins over the piece color', () {
      final grid = GridMatrix()
        ..place(
          PolyominoCatalog.byId('dot').withColor(BlockColor.red),
          0,
          0,
          cell: const GridCell(color: BlockColor.blue),
        );
      expect(grid.at(0, 0)!.color, BlockColor.blue);
    });

    test('color is saved, but a colored plain cell is not "enhanced"', () {
      const cell = GridCell(color: BlockColor.red);
      expect(cell.isEnhanced, isFalse);
      final back = GridCell.fromJson(cell.toJson());
      expect(back.color, BlockColor.red);
      expect(
        const GridCell().toJson(),
        isEmpty,
        reason: 'old format unchanged',
      );
    });

    test('a whole board round-trips its colors', () {
      final g = GridMatrix()
        ..place(
          PolyominoCatalog.byId('bar3_h').withColor(BlockColor.blue),
          1,
          1,
        )
        ..place(PolyominoCatalog.byId('dot').withColor(BlockColor.red), 5, 5);
      final back = GridMatrix.fromJson(g.toJson());
      expect(back.at(1, 2)!.color, BlockColor.blue);
      expect(back.at(5, 5)!.color, BlockColor.red);
      expect(back.toJson(), g.toJson());
    });

    test('Chisel-style edits keep the color', () {
      const cell = GridCell(color: BlockColor.green);
      final steel = cell.copyWith(enhancement: CellEnhancement.steel);
      expect(steel.color, BlockColor.green);
      expect(steel.enhancement, CellEnhancement.steel);
    });
  });
}
