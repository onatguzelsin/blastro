import 'dart:math';

import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/helpful_piece_picker.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// A board with [cells] cells filled, packed from the top-left.
GridMatrix _filled(int cells) {
  final g = GridMatrix();
  for (var i = 0; i < cells; i++) {
    g.setCell(i ~/ 8, i % 8, GridCell.plain);
  }
  return g;
}

List<String> _ids(BlockBag bag, int trays, {GridMatrix? board}) => [
  for (var i = 0; i < trays; i++)
    ...bag.drawTray(board: board).map((p) => p.id),
];

void main() {
  group('when the board counts as crowded', () {
    test('MORE than 70% filled: 44 of 64 is not, 45 of 64 is', () {
      expect(HelpfulPiecePicker.crowdedAbove, 0.70);
      expect(HelpfulPiecePicker.isCrowded(_filled(44)), isFalse); // 68.75%
      expect(HelpfulPiecePicker.isCrowded(_filled(45)), isTrue); // 70.3%
      expect(HelpfulPiecePicker.isCrowded(_filled(0)), isFalse);
      expect(HelpfulPiecePicker.isCrowded(_filled(64)), isTrue);
    });
  });

  group('the weighting', () {
    // Rows 0-5 full: only two rows of room, so tall pieces fit nowhere.
    final board = _filled(48);

    test('a piece that fits is much likelier than one that does not', () {
      final fits = PolyominoCatalog.byId('bar2_h');
      final noFit = PolyominoCatalog.byId('bar5_v');
      expect(
        HelpfulPiecePicker.weightOf(fits, board),
        greaterThan(HelpfulPiecePicker.weightOf(noFit, board) * 5),
      );
    });

    test('smaller pieces get more weight than big ones', () {
      final dot = PolyominoCatalog.byId('dot');
      final cube = PolyominoCatalog.byId('rect_3x3');
      expect(
        HelpfulPiecePicker.sizeWeight(dot),
        greaterThan(HelpfulPiecePicker.sizeWeight(cube)),
      );
    });

    test('every piece keeps a real chance (it is a nudge, not a rule)', () {
      for (final p in PolyominoCatalog.all) {
        expect(HelpfulPiecePicker.weightOf(p, board), greaterThan(0));
      }
    });

    test('pick returns a valid index and uses exactly one random number', () {
      final remaining = PolyominoCatalog.all;
      final a = Random(4);
      final b = Random(4);
      final i = HelpfulPiecePicker.pick(remaining, board, a);
      b.nextDouble();
      expect(i, inInclusiveRange(0, remaining.length - 1));
      expect(a.nextInt(1000000), b.nextInt(1000000));
    });
  });

  group('dealing', () {
    final crowded = _filled(48);

    test('a normal bag ignores the board completely', () {
      expect(_ids(BlockBag(5), 30, board: crowded), _ids(BlockBag(5), 30));
    });

    test('an adaptive bag deals exactly as normal on a roomy board', () {
      for (final cells in [0, 20, 44]) {
        expect(
          _ids(BlockBag(5, adaptive: true), 30, board: _filled(cells)),
          _ids(BlockBag(5), 30),
          reason: '$cells cells',
        );
      }
      expect(
        _ids(BlockBag(5, adaptive: true), 30),
        _ids(BlockBag(5), 30),
        reason: 'no board given',
      );
    });

    test('on a crowded board, many more pieces fit than without the help', () {
      double fitShare(bool adaptive) {
        var fit = 0, total = 0;
        for (var seed = 0; seed < 150; seed++) {
          final bag = BlockBag(seed, adaptive: adaptive);
          for (final p in bag.drawTray(board: crowded)) {
            total++;
            if (FitValidator.fitsAnywhere(crowded, p)) fit++;
          }
        }
        return fit / total;
      }

      final without = fitShare(false);
      final withHelp = fitShare(true);
      expect(without, inInclusiveRange(0.45, 0.70));
      expect(withHelp, greaterThan(without + 0.15));
    });

    test('and the dealt pieces are smaller on average', () {
      double tier(bool adaptive) {
        var sum = 0, n = 0;
        for (var seed = 0; seed < 150; seed++) {
          for (final p in BlockBag(
            seed,
            adaptive: adaptive,
          ).drawTray(board: crowded)) {
            sum += p.dangerTier;
            n++;
          }
        }
        return sum / n;
      }

      expect(tier(true), lessThan(tier(false)));
    });

    test('it is still a bag: a full cycle deals each shape exactly once', () {
      final bag = BlockBag(8, adaptive: true);
      final ids = [for (var i = 0; i < 24; i++) bag.draw(board: crowded).id];
      expect(ids.toSet().length, 24);
    });

    test('the same seed gives the same help', () {
      expect(
        _ids(BlockBag(3, adaptive: true, traySize: 4), 20, board: crowded),
        _ids(BlockBag(3, adaptive: true, traySize: 4), 20, board: crowded),
      );
    });

    test('helped draws are counted in the save', () {
      final bag = BlockBag(2, adaptive: true)..drawTray();
      expect(bag.snapshot().assistDraws, 0, reason: 'no board, no help');
      bag.drawTray(board: crowded);
      expect(bag.snapshot().assistDraws, 3);
      bag.drawTray(board: _filled(10));
      expect(bag.snapshot().assistDraws, 3, reason: 'roomy board: no help');
      expect(bag.snapshot().toJson()['assist'], 3);
    });

    test('a restored adaptive bag deals exactly what the original would', () {
      final bag = BlockBag(13, adaptive: true, traySize: 4);
      for (var i = 0; i < 7; i++) {
        bag.drawTray(board: i.isEven ? crowded : _filled(10));
      }
      final restored = BlockBag.restore(
        BlockBagSnapshot.fromJson(bag.snapshot().toJson()),
        traySize: 4,
        adaptive: true,
      );
      for (var i = 0; i < 25; i++) {
        final a = bag.drawTray(board: crowded);
        final b = restored.drawTray(board: crowded);
        expect(b.map((p) => p.id), a.map((p) => p.id), reason: 'tray $i');
        expect(b.map((p) => p.color), a.map((p) => p.color));
      }
    });

    test('older snapshots without help counts still restore', () {
      final json = BlockBag(1).snapshot().toJson()..remove('assist');
      expect(BlockBagSnapshot.fromJson(json).assistDraws, 0);
    });
  });
}
