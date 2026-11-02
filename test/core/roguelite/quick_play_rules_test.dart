import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/grid/line_detector.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

LineClears _lines(int rows, int cols) => LineClears(
  rows: [for (var i = 0; i < rows; i++) i],
  cols: [for (var i = 0; i < cols; i++) i],
);

void main() {
  group('the mode', () {
    test('normal: 3-piece trays, no refund, no help', () {
      expect(RunMode.normal.traySize, 3);
      expect(RunMode.normal.trayRefundPerClearedCell, 0);
      expect(RunMode.normal.adaptiveDealing, isFalse);
      expect(RunMode.normal.isQuickPlay, isFalse);
    });

    test('Quick Play: 4-piece trays, +1 tray per cleared cell, adaptive', () {
      expect(RunMode.quickPlay.traySize, 4);
      expect(RunMode.quickPlay.trayRefundPerClearedCell, 1);
      expect(RunMode.quickPlay.adaptiveDealing, isTrue);
      expect(RunMode.quickPlay.isQuickPlay, isTrue);
    });
  });

  group('4-piece trays', () {
    test('a Quick Play bag deals 4 pieces; a normal bag still deals 3', () {
      expect(BlockBag(1, traySize: 4).drawTray().length, 4);
      expect(BlockBag(1).drawTray().length, 3);
      expect(BlockBag(1).traySize, BlockBag.defaultTraySize);
      expect(BlockBag.defaultTraySize, 3);
    });

    test('every tray takes exactly 4 pieces out of the bag', () {
      final bag = BlockBag(7, traySize: 4);
      expect(bag.remaining.length, 24);
      for (var t = 1; t <= 5; t++) {
        bag.drawTray();
        expect(bag.remaining.length, 24 - 4 * t);
      }
    });

    test('6 trays use up the 24-piece bag, each shape exactly once', () {
      final bag = BlockBag(3, traySize: 4);
      final ids = [
        for (var t = 0; t < 6; t++) ...bag.drawTray().map((p) => p.id),
      ];
      expect(ids.length, 24);
      expect(ids.toSet().length, 24);
      expect(bag.remaining, isEmpty);
      expect(bag.drawTray().length, 4, reason: 'refills and keeps going');
    });

    test('the tray size survives a save and restore', () {
      final bag = BlockBag(21, traySize: 4)
        ..drawTray()
        ..drawTray();
      final snap = BlockBagSnapshot.fromJson(bag.snapshot().toJson());
      final restored = BlockBag.restore(snap, traySize: 4);
      expect(restored.traySize, 4);
      for (var i = 0; i < 12; i++) {
        final a = bag.drawTray();
        final b = restored.drawTray();
        expect(b.length, 4);
        expect(b.map((p) => p.id), a.map((p) => p.id));
        expect(b.map((p) => p.color), a.map((p) => p.color));
      }
    });

    test('the tray size does not change the order shapes come out in', () {
      final three = [
        for (final p in BlockBag(9).drawTray()) p.id,
        for (final p in BlockBag(9).drawTray()) p.id,
      ];
      final bag = BlockBag(9, traySize: 4);
      final flat = [for (var i = 0; i < 6; i++) bag.draw().id];
      expect(flat.take(3), three.take(3));
    });
  });

  group('2x starting resources', () {
    final quick = StarterDecks.quickPlay;
    final standard = StarterDecks.standard;

    test('10 trays and 6 discards: exactly double the Standard 5 and 3', () {
      expect(quick.traysPerBlind, 10);
      expect(quick.discardsPerBlind, 6);
      expect(quick.traysPerBlind, standard.traysPerBlind * 2);
      expect(quick.discardsPerBlind, standard.discardsPerBlind * 2);
    });

    test('same shapes and colors as Standard', () {
      expect(quick.pool.length, 24);
      expect(quick.colors.length, 4);
    });

    test(
      'it is not one of the five decks you can pick, but is found by id',
      () {
        expect(StarterDecks.all.length, 5);
        expect(StarterDecks.all.contains(quick), isFalse);
        expect(StarterDecks.maybeById('deck_quick_play'), same(quick));
      },
    );
  });

  group('the pre-equipped loadout', () {
    test('5 jokers, in order: Blueprint, Grand Architect, Cornerstone, '
        'Heavyweight, Streak Saver', () {
      expect(QuickPlay.loadoutIds, [
        'joker_blueprint',
        'joker_grand_architect',
        'joker_cornerstone',
        'joker_heavyweight',
        'joker_streak_saver',
      ]);
      expect(QuickPlay.loadout().map((j) => j.id), QuickPlay.loadoutIds);
    });

    test('every one exists in the registry and fills all five slots', () {
      for (final id in QuickPlay.loadoutIds) {
        expect(JokerRegistry.maybeById(id), isNotNull, reason: id);
      }
      expect(QuickPlay.loadout().length, 5);
    });

    test('Blueprint copies Grand Architect: x1.5 per line, twice over', () {
      GridMatrix rows(int n) {
        final g = GridMatrix();
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < 8; c++) {
            g.setCell(r, c, GridCell.plain);
          }
        }
        return g..setCell(7, 7, GridCell.plain);
      }

      double mult(List<String> ids, int lines) => const ScoringPipeline()
          .score(
            board: rows(lines),
            comboStreak: 0,
            jokers: [for (final id in ids) JokerRegistry.byId(id).joker],
          )
          .totalMult;
      final base = mult([], 1);
      expect(mult(['joker_grand_architect'], 1), base * 1.5);
      expect(
        mult(['joker_blueprint', 'joker_grand_architect'], 1),
        closeTo(base * 2.25, 1e-9),
      );
    });
  });

  group('the tray refund: exactly +1 per DISTINCT cleared cell', () {
    int refund(int rows, int cols) =>
        RunMode.quickPlay.trayRefund(_lines(rows, cols));

    test('a single line (row or column) is +8 trays', () {
      expect(refund(1, 0), 8);
      expect(refund(0, 1), 8);
    });

    test('a Cross Clear is +15 (the shared cell counts once)', () {
      expect(refund(1, 1), 15);
    });

    test('two parallel lines are +16', () {
      expect(refund(2, 0), 16);
      expect(refund(0, 2), 16);
    });

    test('bigger clears: triple 24, double cross 28, zone 39, quad 32', () {
      expect(refund(3, 0), 24);
      expect(refund(2, 2), 28);
      expect(refund(3, 3), 39);
      expect(refund(4, 0), 32);
      expect(refund(2, 1), 22, reason: '3 lines, 2 shared cells');
      expect(refund(8, 0), 64);
      expect(refund(8, 8), 64, reason: 'the whole board');
    });

    test('nothing cleared is nothing refunded', () {
      expect(refund(0, 0), 0);
      expect(RunMode.quickPlay.trayRefund(const LineClears()), 0);
    });

    test('normal runs never refund', () {
      for (final (r, c) in [(1, 0), (1, 1), (2, 0), (3, 3)]) {
        expect(RunMode.normal.trayRefund(_lines(r, c)), 0);
      }
    });

    test('the formula matches the real number of cells that vanish', () {
      // Every combination of full rows and columns: count the cells on a
      // board before and after clearing them.
      for (var rows = 0; rows <= 8; rows++) {
        for (var cols = 0; cols <= 8; cols++) {
          final clears = _lines(rows, cols);
          final g = GridMatrix.fromAscii(List.filled(8, 'XXXXXXXX'));
          final before = g.occupiedCount;
          g.clearLines(rows: clears.rows, cols: clears.cols);
          expect(
            clears.cellCount,
            before - g.occupiedCount,
            reason: '$rows rows + $cols cols',
          );
        }
      }
    });

    test('a real full row is detected as 8 cells', () {
      final g = GridMatrix.fromAscii(['XXXXXXXX']);
      expect(LineDetector.detect(g).cellCount, 8);
      expect(RunMode.quickPlay.trayRefund(LineDetector.detect(g)), 8);
    });

    test('a real cross on the board is 15', () {
      final g = GridMatrix.fromAscii(['XXXXXXXX']);
      for (var r = 0; r < 8; r++) {
        g.setCell(r, 0, GridCell.plain);
      }
      expect(RunMode.quickPlay.trayRefund(LineDetector.detect(g)), 15);
    });
  });

  test('the catalog still has 24 shapes for the Quick Play bag', () {
    expect(PolyominoCatalog.all.length, 24);
  });
}
