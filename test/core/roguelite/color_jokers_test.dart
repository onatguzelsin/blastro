import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

ScoreResult _score(GridMatrix g, [List<String> ids = const []]) =>
    const ScoringPipeline().score(
      board: g,
      comboStreak: 0,
      jokers: [for (final id in ids) JokerRegistry.byId(id).joker],
    );

/// Row 0 filled with [colors] (8 entries), plus a spare cell so it isn't a
/// Clean Sweep.
GridMatrix _row(List<BlockColor?> colors) {
  final g = GridMatrix();
  for (var c = 0; c < 8; c++) {
    g.setCell(0, c, GridCell(color: colors[c]));
  }
  return g..setCell(7, 7, GridCell.plain);
}

List<BlockColor?> _of(BlockColor? c) => List.filled(8, c);

void main() {
  test('both color jokers exist, are Common and cheap', () {
    for (final id in ['joker_red_rush', 'joker_blue_tide']) {
      final d = JokerRegistry.byId(id);
      expect(d.rarity, JokerRarity.common);
      expect(d.basePrice, inInclusiveRange(6, 7));
    }
  });

  group('Red Rush: +1 Mult per red cell that scores', () {
    test('an all-red row adds 8 Mult', () {
      final base = _score(_row(_of(BlockColor.red))).totalMult;
      expect(
        _score(_row(_of(BlockColor.red)), ['joker_red_rush']).totalMult,
        base + 8,
      );
    });

    test('a half red row adds 4, and chips are unchanged', () {
      final colors = [
        ...List.filled(4, BlockColor.red),
        ...List.filled(4, BlockColor.blue),
      ];
      final base = _score(_row(colors));
      final withJoker = _score(_row(colors), ['joker_red_rush']);
      expect(withJoker.totalMult, base.totalMult + 4);
      expect(withJoker.totalChips, base.totalChips);
    });

    test('no red cells, uncolored cells or other colors: no effect', () {
      for (final c in [
        null,
        BlockColor.blue,
        BlockColor.green,
        BlockColor.yellow,
      ]) {
        expect(
          _score(_row(_of(c)), ['joker_red_rush']).totalMult,
          _score(_row(_of(c))).totalMult,
          reason: '$c',
        );
      }
    });
  });

  group('Blue Tide: +8 Chips per blue cell that scores', () {
    test('an all-blue row adds 64 Chips', () {
      final base = _score(_row(_of(BlockColor.blue))).totalChips;
      expect(
        _score(_row(_of(BlockColor.blue)), ['joker_blue_tide']).totalChips,
        base + 64,
      );
    });

    test('3 blue cells add 24 Chips, mult is unchanged', () {
      final colors = [
        ...List.filled(3, BlockColor.blue),
        ...List.filled(5, BlockColor.red),
      ];
      final base = _score(_row(colors));
      final withJoker = _score(_row(colors), ['joker_blue_tide']);
      expect(withJoker.totalChips, base.totalChips + 24);
      expect(withJoker.totalMult, base.totalMult);
    });

    test('red cells do nothing for it', () {
      expect(
        _score(_row(_of(BlockColor.red)), ['joker_blue_tide']).totalChips,
        _score(_row(_of(BlockColor.red))).totalChips,
      );
    });
  });

  test('a Cross Clear intersection cell scores (and pays) twice', () {
    final g = GridMatrix();
    for (var i = 0; i < 8; i++) {
      g.setCell(0, i, const GridCell(color: BlockColor.red));
      g.setCell(i, 0, const GridCell(color: BlockColor.red));
    }
    g.setCell(7, 7, GridCell.plain);
    final base = _score(g).totalMult;
    // 15 red cells in the cross, with (0,0) counted on both visits = 16.
    expect(_score(g, ['joker_red_rush']).totalMult, base + 16);
  });

  test('both together on a two-color row', () {
    final colors = [
      ...List.filled(5, BlockColor.red),
      ...List.filled(3, BlockColor.blue),
    ];
    final base = _score(_row(colors));
    final both = _score(_row(colors), ['joker_red_rush', 'joker_blue_tide']);
    expect(both.totalMult, base.totalMult + 5);
    expect(both.totalChips, base.totalChips + 24);
  });
}
