import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

const _pipeline = ScoringPipeline();

GridMatrix _row({List<(int, int, GridCell)> extra = const []}) {
  final g = GridMatrix.fromAscii(['XXXXXXXX'])..setCell(5, 5, GridCell.plain);
  for (final (r, c, cell) in extra) {
    g.setCell(r, c, cell);
  }
  return g;
}

ScoreResult _run(
  BossBlind boss,
  GridMatrix g, {
  List<String> jokers = const [],
  List<ClearArchetype> used = const [],
}) => _pipeline.score(
  board: g,
  comboStreak: 0,
  boss: boss,
  usedArchetypes: used,
  jokers: [for (final id in jokers) JokerRegistry.byId(id).joker],
);

void main() {
  test('10 unique bosses incl. the named ones', () {
    expect(BossRegistry.all.length, 10);
    expect(BossRegistry.all.map((b) => b.id).toSet().length, 10);
    expect(
      BossRegistry.all.map((b) => b.name),
      containsAll([
        'The Wall', 'The Needle', 'The Water', 'The Flint', 'The Eye',
        'The Pillar', 'Violet Vessel', //
      ]),
    );
    expect(BossRegistry.byId('boss_wall'), BossRegistry.wall);
    expect(() => BossRegistry.byId('x'), throwsArgumentError);
  });

  test(
    'Wall quadruples the target; Violet Vessel keeps the 100,000 Finisher',
    () {
      expect(BossRegistry.wall.targetMultiplier, 4.0);
      final base = AnteScaling.baseTarget(8);
      expect(
        (base * BossRegistry.violetVessel.targetMultiplier).round(),
        100000,
      );
    },
  );

  test('Needle and Water set tray and discard rules', () {
    expect(BossRegistry.needle.fixedTrays, 2);
    expect(BossRegistry.water.noDiscards, isTrue);
    expect(BossRegistry.tooth.goldLossPerClear, 1);
  });

  test('Flint halves base Chips and Mult', () {
    final r = _run(BossRegistry.flint, _row());
    expect([r.totalChips, r.totalMult], [5 + 80, 0.5]);
  });

  test('Eye: a repeated archetype scores 0, a new one still scores', () {
    final repeat = _run(
      BossRegistry.eye,
      _row(),
      used: [ClearArchetype.single],
    );
    expect(repeat.finalScore, 0);
    expect(repeat.blockedByBoss, isTrue);
    expect(repeat.clears.rows, [0], reason: 'lines still clear');
    expect(
      _run(BossRegistry.eye, _row(), used: [ClearArchetype.quad]).finalScore,
      greaterThan(0),
    );
  });

  test('Mouth: only the first archetype keeps scoring', () {
    expect(
      _run(
        BossRegistry.mouth,
        _row(),
        used: [ClearArchetype.quad],
      ).blockedByBoss,
      isTrue,
    );
    expect(
      _run(
        BossRegistry.mouth,
        _row(),
        used: [ClearArchetype.single],
      ).finalScore,
      greaterThan(0),
    );
    expect(_run(BossRegistry.mouth, _row()).finalScore, greaterThan(0));
  });

  test('Pillar skips the residue scan', () {
    const steel = GridCell(enhancement: CellEnhancement.steel);
    final g = _row(extra: [(6, 6, steel)]);
    expect(_run(BossRegistry.pillar, g).totalMult, 1);
    expect(_run(BossRegistry.water, g).totalMult, 1.5);
  });

  test('Violet Vessel halves joker XMult (x2 -> x1.5)', () {
    final g = _row();
    expect(
      _run(BossRegistry.water, g, jokers: ['joker_amplifier']).totalMult,
      1.5,
    );
    const vessel = BossRegistry.violetVessel;
    final r = _run(vessel, g, jokers: ['joker_amplifier', 'joker_tidy_up']);
    expect(r.totalMult, 1 * 1.25 * 1.5);
  });

  test('Window ignores enhancements and editions', () {
    const bonus = GridCell(
      enhancement: CellEnhancement.bonus,
      edition: CellEdition.holo,
    );
    final g = _row(extra: [(0, 3, bonus)]);
    expect(_run(BossRegistry.window, g).totalChips, 90);
    expect(_run(BossRegistry.window, g).totalMult, 1);
    expect(_run(BossRegistry.water, g).totalChips, 120);
  });

  test('pick: Finisher on every 8th ante, seeded and regular otherwise', () {
    expect(BossRegistry.pick(8, 1), BossRegistry.violetVessel);
    expect(BossRegistry.pick(16, 9), BossRegistry.violetVessel);
    for (var ante = 1; ante < 40; ante++) {
      if (ante % 8 == 0) continue;
      final b = BossRegistry.pick(ante, 42);
      expect(b.finisher, isFalse);
      expect(BossRegistry.pick(ante, 42), b);
    }
  });
}
