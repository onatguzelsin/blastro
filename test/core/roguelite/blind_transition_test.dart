import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_transition.dart';
import 'package:flutter_test/flutter_test.dart';

GridMatrix _board() => GridMatrix.fromAscii(['XX.X', '.X', 'X'])
  ..setCell(
    4,
    4,
    const GridCell(
      enhancement: CellEnhancement.steel,
      edition: CellEdition.foil,
      seal: CellSeal.red,
    ),
  );

BlindEntry _enter(
  BlindType blind, {
  int ante = 1,
  GridMatrix? grid,
  BlockBag? bag,
}) => BlindTransition.enterNext(
  ante: ante,
  blind: blind,
  grid: grid ?? _board(),
  bag: bag ?? BlockBag(7),
);

void main() {
  group('blind order', () {
    test('Small -> Big -> Boss -> next ante Small', () {
      expect(BlindTransition.nextBlind(BlindType.small), BlindType.big);
      expect(BlindTransition.nextBlind(BlindType.big), BlindType.boss);
      expect(BlindTransition.nextBlind(BlindType.boss), BlindType.small);
    });

    test('only a Boss advances the ante, capped at Ante 39', () {
      expect(BlindTransition.nextAnte(3, BlindType.small), 3);
      expect(BlindTransition.nextAnte(3, BlindType.big), 3);
      expect(BlindTransition.nextAnte(3, BlindType.boss), 4);
      expect(BlindTransition.nextAnte(39, BlindType.boss), 39);
    });
  });

  group('Board Persistence within an Ante', () {
    for (final blind in [BlindType.small, BlindType.big]) {
      test('${blind.name} -> next: every occupied cell stays intact', () {
        final before = _board();
        final entry = _enter(blind, grid: before);
        expect(entry.boardReset, isFalse);
        expect(entry.grid.toJson(), before.toJson());
        expect(entry.ante, 1);
      });
    }

    test('enhancements, editions and seals survive the transition', () {
      final cell = _enter(BlindType.small).grid.at(4, 4)!;
      expect(cell.enhancement, CellEnhancement.steel);
      expect(cell.edition, CellEdition.foil);
      expect(cell.seal, CellSeal.red);
    });

    test('the input board is never mutated and the result is a copy', () {
      final before = _board();
      final entry = _enter(BlindType.big, grid: before);
      entry.grid.setCell(7, 7, GridCell.plain);
      expect(before.isOccupied(7, 7), isFalse);
    });

    test('a defeated Boss resets the board and starts the next ante', () {
      final entry = _enter(BlindType.boss, ante: 2);
      expect(entry.boardReset, isTrue);
      expect(entry.grid.isEmpty, isTrue);
      expect([entry.ante, entry.blind], [3, BlindType.small]);
    });
  });

  group('Full tray refresh on blind transition', () {
    test('a brand-new full 3-piece tray is dealt', () {
      for (final blind in BlindType.values) {
        final entry = _enter(blind);
        expect(entry.tray.length, 3, reason: blind.name);
      }
    });

    test('the new tray is the next 3 pieces drawn from the bag', () {
      final bag = BlockBag(11);
      final spare = BlockBag(11);
      final leftover = bag.drawTray(); // the tray the player was holding
      spare.drawTray();
      final entry = _enter(BlindType.small, bag: bag);
      final expected = spare.drawTray().map((p) => p.id).toList();
      expect(entry.tray.map((p) => p.id).toList(), expected);
      expect(leftover.length, 3);
    });

    test('leftover pieces are discarded, never carried over', () {
      final bag = BlockBag(5);
      final held = bag.drawTray();
      final entry = _enter(BlindType.big, bag: bag);
      // Fresh draws without replacement: none of the discarded pieces repeat
      // until the bag reshuffles (24 shapes, 6 drawn so far).
      final heldIds = held.map((p) => p.id).toSet();
      expect(entry.tray.any((p) => heldIds.contains(p.id)), isFalse);
    });

    test('the refresh also happens when a Boss falls', () {
      final entry = _enter(BlindType.boss);
      expect(entry.tray.length, 3);
      expect(entry.grid.isEmpty, isTrue);
    });

    test('the same seed gives the same refreshed tray', () {
      List<String> run() => _enter(
        BlindType.small,
        bag: BlockBag(3),
      ).tray.map((p) => p.id).toList();
      expect(run(), run());
    });

    test('consumes exactly one tray from the bag', () {
      final bag = BlockBag(9);
      final before = bag.remaining.length;
      _enter(BlindType.small, bag: bag);
      expect(bag.remaining.length, before - 3);
    });
  });
}
