import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

RunNotifier _quick(ProviderContainer c, {int seed = 5}) =>
    c.read(runProvider.notifier)..startQuickPlay(seed);

/// [rows] rows filled except their last column (7), plus a spare cell.
GridMatrix _almost({int rows = 1}) {
  final g = GridMatrix();
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < 7; c++) {
      g.setCell(r, c, GridCell.plain);
    }
  }
  return g..setCell(7, 0, GridCell.plain);
}

void main() {
  group('+1 tray for every cell cleared, exactly', () {
    int trays(ProviderContainer c) => c.read(runProvider).traysRemaining;

    test('a single line is +8 trays', () {
      final c = _container();
      final n = _quick(c);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almost(),
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
              ],
            ),
      );
      expect(n.placePiece(0, 0, 7), isTrue);
      expect(trays(c), 18, reason: '10 + 8');
      expect(c.read(runProvider).quickEvent.trayRefund, 8);
      expect(c.read(runProvider).quickEvent.callouts().first, '+8 TRAYS!');
    });

    test('a column works the same', () {
      final c = _container();
      final n = _quick(c);
      final g = GridMatrix();
      for (var r = 0; r < 7; r++) {
        g.setCell(r, 3, GridCell.plain);
      }
      g.setCell(0, 0, GridCell.plain);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: g,
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 7, 3);
      expect(trays(c), 18);
    });

    test('a Cross Clear is +15', () {
      final c = _container();
      final n = _quick(c);
      final g = _almost();
      for (var r = 1; r < 8; r++) {
        g.setCell(r, 7, GridCell.plain);
      }
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: g,
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 0, 7);
      expect(trays(c), 25, reason: '10 + 15');
      expect(c.read(runProvider).quickEvent.trayRefund, 15);
    });

    test('two parallel lines are +16', () {
      final c = _container();
      final n = _quick(c);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almost(rows: 2),
              tray: [
                PolyominoCatalog.byId('bar2_v'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 0, 7);
      expect(trays(c), 26, reason: '10 + 16');
    });

    test('a placement that clears nothing refunds nothing', () {
      final c = _container();
      final n = _quick(c);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: GridMatrix(),
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 3, 3);
      expect(trays(c), 10);
      expect(c.read(runProvider).quickEvent.isEmpty, isTrue);
    });

    test('finishing a tray still costs one tray, on top of the refund', () {
      final c = _container();
      final n = _quick(c);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almost(),
              tray: [PolyominoCatalog.byId('dot'), null, null, null],
            ),
      );
      n.placePiece(0, 0, 7);
      // 10 + 8 refunded - 1 for the tray just finished.
      expect(trays(c), 17);
      expect(c.read(runProvider).tray.length, 4);
      expect(c.read(runProvider).unplaced.length, 4, reason: 'a new tray');
    });

    test('a normal run never refunds, same board and move', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(5);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almost(),
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
              ],
            ),
      );
      final before = c.read(runProvider).traysRemaining;
      n.placePiece(0, 0, 7);
      expect(c.read(runProvider).traysRemaining, before);
      expect(c.read(runProvider).quickEvent.isEmpty, isTrue);
    });

    test('the refund is added immediately, before the tray is dealt again', () {
      final c = _container();
      final n = _quick(c);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almost(),
              tray: [
                PolyominoCatalog.byId('dot'),
                PolyominoCatalog.byId('dot'),
                null,
                null,
              ],
            ),
      );
      n.placePiece(0, 0, 7);
      expect(c.read(runProvider).traysRemaining, 18);
      expect(c.read(runProvider).unplaced.length, 1);
    });
  });
}
