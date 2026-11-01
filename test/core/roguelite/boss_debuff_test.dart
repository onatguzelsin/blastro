import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const _steel = GridCell(enhancement: CellEnhancement.steel);
const _bonus = GridCell(enhancement: CellEnhancement.bonus);
const _foil = GridCell(edition: CellEdition.foil);
const _seal = GridCell(seal: CellSeal.red);

bool _jokerDebuffed(BossBlind b, String id) =>
    b.debuffsJoker(JokerRegistry.byId(id).joker);

void main() {
  group('debuffed blocks', () {
    test(
      'The Window marks enhanced and edition cells, not plain or sealed',
      () {
        const b = BossRegistry.window;
        expect(b.debuffsCell(_bonus), isTrue);
        expect(b.debuffsCell(_steel), isTrue);
        expect(b.debuffsCell(_foil), isTrue);
        expect(b.debuffsCell(GridCell.plain), isFalse);
        expect(b.debuffsCell(_seal), isFalse, reason: 'seals still work');
      },
    );

    test('The Pillar marks Steel (residue) cells only', () {
      const b = BossRegistry.pillar;
      expect(b.debuffsCell(_steel), isTrue);
      expect(b.debuffsCell(_bonus), isFalse);
      expect(b.debuffsCell(GridCell.plain), isFalse);
    });

    test('rule-only bosses never mark any block', () {
      for (final b in [
        BossRegistry.wall, BossRegistry.needle, BossRegistry.water,
        BossRegistry.flint, BossRegistry.eye, BossRegistry.mouth,
        BossRegistry.tooth, BossRegistry.violetVessel, //
      ]) {
        for (final c in [GridCell.plain, _steel, _bonus, _foil, _seal]) {
          expect(b.debuffsCell(c), isFalse, reason: b.name);
        }
      }
    });
  });

  group('debuffed jokers', () {
    test('Violet Vessel marks every XMult joker', () {
      const b = BossRegistry.violetVessel;
      expect(_jokerDebuffed(b, 'joker_amplifier'), isTrue);
      expect(_jokerDebuffed(b, 'joker_3x3_sanctuary'), isTrue);
      expect(_jokerDebuffed(b, 'joker_tidy_up'), isTrue);
    });

    test('Violet Vessel leaves non-XMult jokers alone', () {
      const b = BossRegistry.violetVessel;
      for (final id in [
        'joker_plain', 'joker_chip_collector', 'joker_cornerstone',
        'joker_heavyweight', 'joker_gyroscope', 'joker_combo_banker', //
      ]) {
        expect(_jokerDebuffed(b, id), isFalse, reason: id);
      }
    });

    test('The Pillar marks residue jokers (Cornerstone, Mime)', () {
      const b = BossRegistry.pillar;
      expect(_jokerDebuffed(b, 'joker_cornerstone'), isTrue);
      expect(_jokerDebuffed(b, 'joker_mime'), isTrue);
      expect(_jokerDebuffed(b, 'joker_plain'), isFalse);
      expect(_jokerDebuffed(b, 'joker_amplifier'), isFalse);
    });

    test('other bosses never mark a joker', () {
      for (final b in [
        BossRegistry.wall, BossRegistry.needle, BossRegistry.water,
        BossRegistry.flint, BossRegistry.eye, BossRegistry.mouth,
        BossRegistry.tooth, BossRegistry.window, //
      ]) {
        for (final d in JokerRegistry.all) {
          expect(b.debuffsJoker(d.joker), isFalse, reason: '${b.name}/${d.id}');
        }
      }
    });
  });
}
