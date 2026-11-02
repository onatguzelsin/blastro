import 'package:blastro/core/grid/fit_validator.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

RunNotifier _start(ProviderContainer c, StarterDeck d, {int seed = 7}) =>
    c.read(runProvider.notifier)..startRun(seed, d);

void main() {
  group('the bag follows the deck for the whole run', () {
    test('Monolith: 40 new trays and discards deal only squares', () {
      final c = _container();
      final n = _start(c, StarterDecks.monolithCube);
      const allowed = {'rect_2x2', 'rect_3x3'};
      for (var i = 0; i < 40; i++) {
        n.debugSet(
          c
              .read(runProvider)
              .copyWith(status: RunStatus.shopping, blind: BlindType.small),
        );
        n.leaveShop();
        for (final p in c.read(runProvider).unplaced) {
          expect(allowed, contains(p.id));
        }
      }
      n.playBlind();
      n.discardTray();
      expect(
        c.read(runProvider).unplaced.every((p) => allowed.contains(p.id)),
        isTrue,
      );
      expect(n.bagRemaining.every((p) => allowed.contains(p.id)), isTrue);
    });

    test('Monolith: the first tray of a new run is squares', () {
      for (var seed = 0; seed < 25; seed++) {
        final c = _container();
        _start(c, StarterDecks.monolithCube, seed: seed);
        expect(
          c
              .read(runProvider)
              .unplaced
              .every((p) => p.id == 'rect_2x2' || p.id == 'rect_3x3'),
          isTrue,
          reason: 'seed $seed',
        );
      }
    });

    test('Chromatic: every piece is red or blue; Standard shows more', () {
      final c = _container();
      final n = _start(c, StarterDecks.chromaticFlush);
      final seen = <BlockColor?>{};
      for (var i = 0; i < 60; i++) {
        n.debugSet(c.read(runProvider).copyWith(status: RunStatus.shopping));
        n.leaveShop();
        seen.addAll(c.read(runProvider).unplaced.map((p) => p.color));
      }
      expect(seen, {BlockColor.red, BlockColor.blue});

      final c2 = _container();
      final n2 = _start(c2, StarterDecks.standard);
      final seen2 = <BlockColor?>{};
      for (var i = 0; i < 60; i++) {
        n2.debugSet(c2.read(runProvider).copyWith(status: RunStatus.shopping));
        n2.leaveShop();
        seen2.addAll(c2.read(runProvider).unplaced.map((p) => p.color));
      }
      expect(seen2.length, 4);
    });

    test('a placed piece leaves its color on the board', () {
      final c = _container();
      final n = _start(c, StarterDecks.chromaticFlush, seed: 4)..playBlind();
      final s = c.read(runProvider);
      final piece = s.tray[0]!;
      final at = FitValidator.placements(s.grid, piece).first;
      expect(n.placePiece(0, at.row, at.col), isTrue);
      final grid = c.read(runProvider).grid;
      var found = 0;
      for (var r = 0; r < 8; r++) {
        for (var col = 0; col < 8; col++) {
          if (grid.isOccupied(r, col)) {
            expect(grid.at(r, col)!.color, piece.color);
            expect([BlockColor.red, BlockColor.blue], contains(piece.color));
            found++;
          }
        }
      }
      expect(found, piece.cellCount);
    });
  });

  test('the tray piece\'s color survives rotation (Gyroscope)', () {
    final c = _container();
    final n = _start(c, StarterDecks.chromaticFlush)..playBlind();
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(jokers: [JokerRegistry.byId('joker_gyroscope').joker]),
    );
    final before = c.read(runProvider).tray[0]!.color;
    n.rotateTraySlot(0);
    expect(c.read(runProvider).tray[0]!.color, before);
  });

  test('Standard numbers stay the documented constants', () {
    expect(RunState.traysPerBlind, 5);
    expect(RunState.discardsPerBlind, 3);
    expect(AnteScaling.finalAnte, 8);
  });
}
