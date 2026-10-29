import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(int seed) {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(seed);
  return c;
}

void main() {
  test('new run: 3-piece tray, no jokers, ante 1 small blind', () {
    final s = _container(1).read(runProvider);
    expect(s.tray.whereType<Object>().length, 3);
    expect(s.jokers, isEmpty);
    expect([s.ante, s.blind, s.target], [1, BlindType.small, 300]);
    expect(s.traysRemaining, RunState.traysPerBlind);
    expect(s.discards, 3);
  });

  test('same seed deals the same tray', () {
    List<String?> ids(int seed) =>
        _container(seed).read(runProvider).tray.map((p) => p?.id).toList();
    expect(ids(5), ids(5));
  });

  test('valid placement updates grid, tray and combo window', () {
    final c = _container(2);
    final n = c.read(runProvider.notifier);
    final piece = c.read(runProvider).tray[0]!;
    expect(n.placePiece(0, 0, 0), isTrue);
    final s = c.read(runProvider);
    expect(s.tray[0], isNull);
    expect(s.grid.occupiedCount, piece.cellCount);
    expect(s.combo.missesInARow, 1);
    expect(s.scoreSerial, 1);
  });

  test('invalid placement is rejected and leaves state untouched', () {
    final c = _container(2);
    final n = c.read(runProvider.notifier);
    expect(n.placePiece(0, -1, 0), isFalse);
    expect(n.placePiece(0, 8, 0), isFalse);
    expect(n.placePiece(0, 0, 8), isFalse);
    n.placePiece(0, 0, 0);
    final occupied = c.read(runProvider).grid.occupiedCount;
    expect(n.placePiece(1, 0, 0), isFalse, reason: 'overlaps slot 0');
    expect(c.read(runProvider).grid.occupiedCount, occupied);
    expect(c.read(runProvider).placements, 1);
  });

  test('completing a tray deals the next one and spends a tray', () {
    final c = _container(3);
    final n = c.read(runProvider.notifier);
    for (var slot = 0; slot < 3; slot++) {
      final s = c.read(runProvider);
      final at = FitValidator.placements(s.grid, s.tray[slot]!).first;
      expect(n.placePiece(slot, at.row, at.col), isTrue);
    }
    final s = c.read(runProvider);
    expect(s.traysRemaining, RunState.traysPerBlind - 1);
    expect(s.tray.whereType<Object>().length, 3);
  });

  test('clearing a line scores, applies combo and the joker bar', () {
    final c = _container(4);
    final n = c.read(runProvider.notifier);
    final s0 = c.read(runProvider);
    final dot = PolyominoCatalog.byId('dot');
    n.debugSet(
      s0.copyWith(
        grid: GridMatrix.fromAscii(['XXXXXXX.', 'X']),
        tray: [dot, null, null],
      ),
    );
    expect(n.placePiece(0, 0, 7), isTrue);
    final s = c.read(runProvider);
    expect(s.lastScore!.finalScore, greaterThan(0));
    expect(s.score, s.lastScore!.finalScore);
    expect(s.combo.streak, 1);
    expect(s.grid.isOccupied(0, 0), isFalse);
    expect(s.preClearBoard!.isOccupied(0, 0), isTrue);
  });

  test('discard redraws unplaced pieces and spends a charge', () {
    final c = _container(6);
    final n = c.read(runProvider.notifier);
    n.discardTray();
    final s = c.read(runProvider);
    expect(s.discards, 2);
    expect(s.tray.whereType<Object>().length, 3);
  });

  test('lockout with no discards ends the run', () {
    final c = _container(7);
    final n = c.read(runProvider.notifier);
    final bar5 = PolyominoCatalog.byId('bar5_h');
    final checker = GridMatrix.fromAscii([
      for (var r = 0; r < 8; r++)
        List.generate(8, (col) => (r + col) % 2 == 0 ? 'X' : '.').join(),
    ]);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(grid: checker, tray: [bar5, null, null], discards: 0),
    );
    n.discardTray();
    expect(c.read(runProvider).status, RunStatus.playing, reason: 'no charges');
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(grid: checker, tray: [bar5, bar5, bar5], discards: 1),
    );
    n.discardTray();
    expect(c.read(runProvider).discards, 0);
    expect(c.read(runProvider).status, RunStatus.lost);
  });
}
