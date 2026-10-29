import 'dart:math';

import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/blueprint_cards.dart';
import 'package:blastro/core/roguelite/chisel_cards.dart';
import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:flutter_test/flutter_test.dart';

GridMatrix _full() => GridMatrix.fromAscii(List.filled(8, 'XXXXXXXX'));

int _count(GridMatrix g, bool Function(GridCell) test) => [
  for (var r = 0; r < 8; r++)
    for (var c = 0; c < 8; c++)
      if (g.at(r, c) != null && test(g.at(r, c)!)) 1,
].length;

void main() {
  test('10 Blueprint + 10 Chisel cards with unique ids', () {
    expect(blueprintCards.length, 10);
    expect(chiselCards.length, 10);
    expect(ConsumableRegistry.all.map((c) => c.id).toSet().length, 20);
    expect(() => ConsumableRegistry.byId('x'), throwsArgumentError);
  });

  test('each Blueprint levels exactly its own archetype', () {
    expect({
      for (final b in blueprintCards) b.archetype,
    }, ClearArchetype.values.toSet());
    for (final card in blueprintCards) {
      final levels = card.levelUp(const {});
      expect(levels[card.archetype], 2);
      expect(levels.length, 1);
      expect(card.levelUp(levels)[card.archetype], 3);
    }
  });

  test('enhance / edition / seal Chisels edit exactly 2 cells', () {
    for (final card in chiselCards.where(
      (c) => c.kind != ChiselKind.demolish,
    )) {
      final before = _full();
      final after = card.apply(before, Random(1));
      expect(_count(after, (c) => c.isEnhanced), 2, reason: card.id);
      expect(before.occupiedCount, 64);
      expect(_count(before, (c) => c.isEnhanced), 0, reason: 'input untouched');
    }
  });

  test('each Chisel applies its own effect', () {
    GridCell only(String id) {
      final g = chiselCards
          .firstWhere((c) => c.id == id)
          .apply(_full(), Random(2));
      return [
        for (var r = 0; r < 8; r++)
          for (var c = 0; c < 8; c++)
            if (g.at(r, c)!.isEnhanced) g.at(r, c)!,
      ].first;
    }

    expect(only('chisel_bonus').enhancement, CellEnhancement.bonus);
    expect(only('chisel_mult').enhancement, CellEnhancement.mult);
    expect(only('chisel_glass').enhancement, CellEnhancement.glass);
    expect(only('chisel_lucky').enhancement, CellEnhancement.lucky);
    expect(only('chisel_steel').enhancement, CellEnhancement.steel);
    expect(only('chisel_foil').edition, CellEdition.foil);
    expect(only('chisel_holo').edition, CellEdition.holo);
    expect(only('chisel_polychrome').edition, CellEdition.polychrome);
    expect(only('chisel_red_seal').seal, CellSeal.red);
  });

  test('Demolish removes 3 cells; cards keep existing modifiers', () {
    final demolish = chiselCards.firstWhere((c) => c.id == 'chisel_demolish');
    expect(demolish.apply(_full(), Random(3)).occupiedCount, 61);
    final g = GridMatrix.fromAscii(['X'])
      ..setCell(0, 0, const GridCell(edition: CellEdition.foil));
    final steel = chiselCards.firstWhere((c) => c.id == 'chisel_steel');
    final out = steel.apply(g, Random(0)).at(0, 0)!;
    expect(
      [out.enhancement, out.edition],
      [CellEnhancement.steel, CellEdition.foil],
    );
  });

  test('seeded Chisel is deterministic; fewer cells than targets is fine', () {
    final card = chiselCards.first;
    GridMatrix run() => card.apply(_full(), Random(9));
    expect(run().toJson(), run().toJson());
    expect(card.canUse(GridMatrix()), isFalse);
    final one = GridMatrix.fromAscii(['X']);
    expect(_count(card.apply(one, Random(0)), (c) => c.isEnhanced), 1);
  });

  test('grid JSON round trip keeps enhancements', () {
    final g = GridMatrix.fromAscii(['XX'])
      ..setCell(
        0,
        1,
        const GridCell(enhancement: CellEnhancement.steel, seal: CellSeal.red),
      );
    final back = GridMatrix.fromJson(g.toJson());
    expect(back.toJson(), g.toJson());
    expect(back.at(0, 1)!.seal, CellSeal.red);
    expect(back.isOccupied(1, 1), isFalse);
  });
}
