import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container([RunPersistence? store]) {
  final c = ProviderContainer(
    overrides: [runPersistenceProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

/// A run in the shop after beating [blind] of [ante], holding a partial tray
/// and an enhanced cell on the board.
RunNotifier _inShop(
  ProviderContainer c, {
  BlindType blind = BlindType.small,
  int ante = 1,
}) {
  final n = c.read(runProvider.notifier)..newRun(31);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          status: RunStatus.shopping,
          blind: blind,
          ante: ante,
          grid: GridMatrix.fromAscii(['XX', 'X'])
            ..setCell(4, 4, const GridCell(enhancement: CellEnhancement.steel)),
          tray: [PolyominoCatalog.byId('dot'), null, null],
          skipped: [BlindType.small],
        ),
  );
  return n;
}

void main() {
  group('leaving the shop (blind transition)', () {
    test('goes to Blind Select for the next blind, same ante', () {
      final c = _container();
      _inShop(c).leaveShop();
      final s = c.read(runProvider);
      expect(
        [s.status, s.ante, s.blind],
        [RunStatus.blindSelect, 1, BlindType.big],
      );
      expect(s.shop, isNull);
    });

    test('board persistence: occupied and enhanced cells stay intact', () {
      final c = _container();
      final n = _inShop(c);
      final grid = c.read(runProvider).grid.toJson();
      n.leaveShop();
      expect(c.read(runProvider).grid.toJson(), grid);
      expect(
        c.read(runProvider).grid.at(4, 4)!.enhancement,
        CellEnhancement.steel,
      );
    });

    test('leftover tray pieces are discarded for a full new tray', () {
      final c = _container();
      final n = _inShop(c);
      final bagBefore = n.bagRemaining.length;
      n.leaveShop();
      final tray = c.read(runProvider).tray;
      expect(tray.length, 3);
      expect(tray.every((p) => p != null), isTrue, reason: 'full tray');
      expect(
        n.bagRemaining.length,
        bagBefore - 3,
        reason: 'dealt from the bag',
      );
    });

    test('an empty tray is refilled too', () {
      final c = _container();
      final n = _inShop(c);
      n.debugSet(c.read(runProvider).copyWith(tray: [null, null, null]));
      n.leaveShop();
      expect(c.read(runProvider).tray.whereType<Object>().length, 3);
    });

    test('same seed, same refreshed tray', () {
      List<String?> run() {
        final c = _container();
        _inShop(c).leaveShop();
        return c.read(runProvider).tray.map((p) => p?.id).toList();
      }

      expect(run(), run());
    });

    test(
      'a defeated Boss resets the board, starts the next ante, clears skips',
      () {
        final c = _container();
        _inShop(c, blind: BlindType.boss, ante: 2).leaveShop();
        final s = c.read(runProvider);
        expect(
          [s.status, s.ante, s.blind],
          [RunStatus.blindSelect, 3, BlindType.small],
        );
        expect(s.grid.isEmpty, isTrue);
        expect(s.skipped, isEmpty);
        expect(s.tray.whereType<Object>().length, 3);
      },
    );

    test('skips are kept while the ante continues', () {
      final c = _container();
      _inShop(c).leaveShop();
      expect(c.read(runProvider).skipped, [BlindType.small]);
    });

    test('only works from the shop', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(3);
      n.leaveShop();
      expect(c.read(runProvider).status, RunStatus.playing);
    });
  });
}
