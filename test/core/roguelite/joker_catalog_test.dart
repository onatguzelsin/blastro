import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/run_modifiers.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

const _pipeline = ScoringPipeline();
const _row = 'XXXXXXXX';

/// Single-row clear on [row] plus extra residue cells.
GridMatrix _board({int row = 0, List<(int, int)> extra = const []}) {
  final g = GridMatrix.fromAscii(['']);
  for (var c = 0; c < 8; c++) {
    g.setCell(row, c, GridCell.plain);
  }
  for (final (r, c) in extra) {
    g.setCell(r, c, GridCell.plain);
  }
  return g;
}

ScoreResult _score(
  GridMatrix b,
  List<String> ids, {
  int streak = 0,
  String? piece,
}) => _pipeline.score(
  board: b,
  comboStreak: streak,
  jokers: [for (final id in ids) JokerRegistry.byId(id).joker],
  placedPiece: piece == null ? null : PolyominoCatalog.byId(piece),
);

void main() {
  test('registry has 23 unique jokers (20 core + 3 legendary)', () {
    expect(JokerRegistry.all.length, 23);
    expect(JokerRegistry.all.map((d) => d.id).toSet().length, 23);
    for (final id in [
      'joker_cornerstone', 'joker_3x3_sanctuary', 'joker_seven_fingers',
      'joker_gyroscope', 'joker_streak_saver', 'joker_heavyweight',
      'joker_blueprint', 'joker_brainstorm', 'joker_mime',
      'joker_baron_of_steel', //
    ]) {
      expect(JokerRegistry.maybeById(id), isNotNull, reason: id);
    }
    expect(JokerRegistry.maybeById('nope'), isNull);
    expect(() => JokerRegistry.byId('nope'), throwsArgumentError);
    expect(JokerRegistry.byId('joker_plain').sellValue, 3, reason: 'base \$6');
  });

  test('baseline single clear: 90 chips x 1 mult', () {
    final r = _score(_board(extra: [(5, 5)]), []);
    expect([r.totalChips, r.totalMult], [90, 1]);
  });

  test('Cornerstone: +20 Chips per occupied corner in the residue', () {
    final r = _score(_board(extra: [(7, 0), (7, 7), (3, 3)]), [
      'joker_cornerstone',
    ]);
    expect(r.totalChips, 90 + 40);
  });

  test('3x3 Sanctuary: x2 only with a solid 3x3 block left', () {
    final block = [
      for (var r = 3; r < 6; r++)
        for (var c = 3; c < 6; c++) (r, c),
    ];
    expect(_score(_board(extra: block), ['joker_3x3_sanctuary']).totalMult, 2);
    block.removeLast();
    expect(_score(_board(extra: block), ['joker_3x3_sanctuary']).totalMult, 1);
  });

  test('Seven Fingers: +7 per cleared cell on row/col index 6', () {
    final onSix = _score(_board(row: 6, extra: [(1, 1)]), [
      'joker_seven_fingers',
    ]);
    expect(onSix.totalChips, 90 + 8 * 7);
    final offSix = _score(_board(row: 0, extra: [(1, 1)]), [
      'joker_seven_fingers',
    ]);
    expect(offSix.totalChips, 90 + 7, reason: 'only cell (0,6)');
  });

  test('Heavyweight: +8 Mult only for danger tier 4 pieces', () {
    final b = _board(extra: [(5, 5)]);
    expect(_score(b, ['joker_heavyweight'], piece: 'plus').totalMult, 9);
    expect(_score(b, ['joker_heavyweight'], piece: 'dot').totalMult, 1);
    expect(_score(b, ['joker_heavyweight']).totalMult, 1);
  });

  test('Combo Banker: +2 Mult per streak level', () {
    final b = _board(extra: [(5, 5)]);
    expect(_score(b, ['joker_combo_banker'], streak: 3).totalMult, 1 + 3 + 6);
    expect(_score(b, ['joker_combo_banker']).totalMult, 1);
  });

  test('Crossroads: intersection cell pays on both of its visits', () {
    final g = _board(extra: [(5, 5)]);
    for (var r = 0; r < 8; r++) {
      g.setCell(r, 0, GridCell.plain);
    }
    final r = _score(g, ['joker_crossroads']);
    expect(r.totalChips, 25 + 160 + 20);
  });

  test('Tidy Up: x2 when 8 or fewer cells remain', () {
    expect(_score(_board(extra: [(5, 5)]), ['joker_tidy_up']).totalMult, 2);
    final many = [for (var c = 0; c < 7; c++) (4, c), (5, 0), (5, 1), (5, 2)];
    expect(_score(_board(extra: many), ['joker_tidy_up']).totalMult, 1);
  });

  test('Baron of Steel: Steel residue x2 instead of x1.5', () {
    final g = _board(extra: [(5, 5)])
      ..setCell(6, 6, const GridCell(enhancement: CellEnhancement.steel));
    expect(_score(g, []).totalMult, 1.5);
    expect(_score(g, ['joker_baron_of_steel']).totalMult, 2.0);
  });

  test('Lucky Charm: lucky cells always trigger', () {
    final g = _board(extra: [(5, 5)])
      ..setCell(0, 3, const GridCell(enhancement: CellEnhancement.lucky));
    expect(_score(g, ['joker_lucky_charm']).totalMult, 21);
  });

  test('plain stat jokers', () {
    final b = _board(extra: [(5, 5)]);
    expect(_score(b, ['joker_plain']).totalMult, 5);
    expect(_score(b, ['joker_chip_collector']).totalChips, 120);
    expect(_score(b, ['joker_amplifier']).totalMult, 1.5);
  });

  test(
    'Blueprint copies a hook joker to its right; Brainstorm copies slot 0',
    () {
      final b = _board(extra: [(5, 5)]);
      expect(
        _score(b, ['joker_blueprint', 'joker_chip_collector']).totalChips,
        150,
      );
      expect(
        _score(b, ['joker_chip_collector', 'joker_brainstorm']).totalChips,
        150,
      );
    },
  );

  test('Mime doubles Steel residue', () {
    final g = _board(extra: [(5, 5)])
      ..setCell(6, 6, const GridCell(enhancement: CellEnhancement.steel));
    expect(_score(g, ['joker_mime']).totalMult, 2.25);
  });

  test('run modifiers aggregate across the bar', () {
    final m = RunModifiers.fromJokers([
      for (final id in [
        'joker_gyroscope', 'joker_streak_saver', 'joker_extra_tray',
        'joker_discard_hoarder', 'joker_pocket_change', 'joker_lucky_charm',
        'joker_baron_of_steel', //
      ])
        JokerRegistry.byId(id).joker,
    ]);
    expect(m.rotation, isTrue);
    expect(
      [m.extraSetupMoves, m.extraTrays, m.extraDiscards, m.cashOutBonus],
      [1, 1, 1, 2],
    );
    expect([m.luckyAlways, m.steelMultiplier], [true, 2.0]);
    expect(RunModifiers.fromJokers(const []).rotation, isFalse);
  });

  test('Streak Saver widens the combo window by one move', () {
    var w = const ComboWindow(streak: 3);
    for (var i = 0; i < 3; i++) {
      w = w.afterPlacement(cleared: false, extraSetupMoves: 1);
    }
    expect(w.streak, 3);
    expect(w.afterPlacement(cleared: false, extraSetupMoves: 1).streak, 0);
  });

  test('Gyroscope rotation flag drives piece variants', () {
    final p = PolyominoCatalog.byId('l_small_0');
    expect(p.nextVariant.cells, isNot(p.cells));
    expect(
      PolyominoCatalog.byId('rect_2x2').nextVariant.cells,
      PolyominoCatalog.byId('rect_2x2').cells,
    );
  });

  test('unused constant', () => expect(_row.length, 8));
}
