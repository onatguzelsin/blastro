import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/joker_effects.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/core/scoring/score_accumulator.dart';
import 'package:blastro/core/scoring/score_step_event.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

const _pipeline = ScoringPipeline();
const _row0 = 'XXXXXXXX';

GridMatrix _rowAndColumn() => GridMatrix.fromAscii([
  _row0, 'X', 'X', 'X', 'X', 'X', 'X', 'X', //
])..setCell(5, 5, GridCell.plain); // residue so it is not a CleanSweep

double _mult(ClearArchetype a) => ClearArchetypes.base[a]!.mult.toDouble();
double _chips(ClearArchetype a) => ClearArchetypes.base[a]!.chips.toDouble();

void main() {
  group('Phase 3: board residue', () {
    const steel = GridCell(enhancement: CellEnhancement.steel);

    test('Steel residue grants x1.5 each, scanned (0,0)->(7,7)', () {
      final board = GridMatrix.fromAscii([_row0])
        ..setCell(6, 1, steel)
        ..setCell(2, 4, steel)
        ..setCell(2, 2, GridCell.plain);
      final r = _pipeline.score(board: board, comboStreak: 0);
      final steps = r.events
          .where((e) => e.kind == ScoreStepKind.residueSteel)
          .toList();
      expect(steps.map((e) => [e.row, e.col]), [
        [2, 4],
        [6, 1],
      ]);
      expect(r.totalMult, _mult(ClearArchetype.single) * 1.5 * 1.5);
      expect(steps.every((e) => e.phase == ScorePhase.residue), isTrue);
    });

    test('Steel inside a cleared line is NOT residue', () {
      final board = GridMatrix.fromAscii([_row0])
        ..setCell(0, 4, steel)
        ..setCell(5, 5, GridCell.plain);
      final r = _pipeline.score(board: board, comboStreak: 0);
      expect(
        r.events.where((e) => e.kind == ScoreStepKind.residueSteel),
        isEmpty,
      );
      expect(r.totalMult, _mult(ClearArchetype.single));
    });

    test('Mime retriggers residue', () {
      final board = GridMatrix.fromAscii([_row0])..setCell(6, 1, steel);
      final r = _pipeline.score(
        board: board,
        comboStreak: 0,
        jokers: const [Joker.mime()],
      );
      expect(r.totalMult, _mult(ClearArchetype.single) * 1.5 * 1.5);
    });
  });

  group('Phase 4: Joker order of operations', () {
    const plus7Mult = Joker(id: 'plus7', mult: 7);
    const x2 = Joker(id: 'x2', xMult: 2.0);

    int run(List<Joker> bar) {
      final acc = ScoreAccumulator(chips: 4, mult: 2);
      JokerBar.apply(acc, bar);
      return acc.total;
    }

    test('+Mult before XMult = 72; XMult before +Mult = 44', () {
      expect(run([plus7Mult, x2]), 72); // 4 * ((2 + 7) * 2)
      expect(run([x2, plus7Mult]), 44); // 4 * ((2 * 2) + 7)
    });

    test('chips jokers are order-independent: (10+4+10) * 1.5 * 2.0 = 72', () {
      final acc = ScoreAccumulator(chips: 10, mult: 1);
      JokerBar.apply(acc, const [
        Joker(id: 'c4', chips: 4),
        Joker(id: 'c10', chips: 10),
        Joker(id: 'x15', xMult: 1.5),
        Joker(id: 'x2', xMult: 2.0),
      ]);
      expect(acc.chips, 24);
      expect(acc.total, 72);
    });

    test('Blueprint copies right; Brainstorm copies index 0', () {
      expect(run([const Joker.blueprint(), plus7Mult]), (2 + 7 + 7) * 4);
      expect(run([plus7Mult, const Joker.brainstorm()]), (2 + 7 + 7) * 4);
      expect(run([const Joker.blueprint()]), 8, reason: 'nothing to copy');
      expect(run([const Joker.brainstorm()]), 8, reason: 'cannot copy itself');
      expect(
        run([const Joker.blueprint(), const Joker.brainstorm()]),
        8,
        reason: 'circular copy chain yields nothing',
      );
    });

    test('pipeline applies jokers after residue, left to right', () {
      final board = GridMatrix.fromAscii([_row0])
        ..setCell(5, 5, GridCell.plain);
      final a = _pipeline.score(
        board: board,
        comboStreak: 0,
        jokers: [plus7Mult, x2],
      );
      final b = _pipeline.score(
        board: board,
        comboStreak: 0,
        jokers: [x2, plus7Mult],
      );
      expect(a.finalScore, isNot(b.finalScore));
      final m = _mult(ClearArchetype.single);
      expect(a.totalMult, (m + 7) * 2);
      expect(b.totalMult, m * 2 + 7);
    });
  });

  group('Events and CleanSweep', () {
    test('CleanSweep adds +360 after Chips x Mult', () {
      final board = GridMatrix.fromAscii([_row0]);
      final r = _pipeline.score(board: board, comboStreak: 0);
      expect(r.archetype, ClearArchetype.cleanSweep);
      expect(r.allClearBonus, 360);
      expect(
        r.finalScore,
        ((_chips(ClearArchetype.cleanSweep) + 80) *
                    _mult(ClearArchetype.cleanSweep))
                .floor() +
            360,
      );
    });

    test('phases are ordered; last event is finalScore; haptics escalate', () {
      final board = _rowAndColumn()
        ..setCell(6, 6, const GridCell(enhancement: CellEnhancement.steel));
      final r = _pipeline.score(
        board: board,
        comboStreak: 1,
        jokers: const [Joker(id: 'x2', xMult: 2.0)],
      );
      final phases = r.events.map((e) => e.phase.index).toList();
      expect([...phases]..sort(), phases);
      expect(r.events.last.kind, ScoreStepKind.finalScore);
      expect(r.events.first.haptic, HapticIntensity.none);
      expect(
        r.events.firstWhere((e) => e.kind == ScoreStepKind.cellChips).haptic,
        HapticIntensity.light,
      );
      expect(
        r.events.firstWhere((e) => e.kind == ScoreStepKind.jokerXMult).haptic,
        HapticIntensity.heavy,
      );
    });

    test('running totals replay to the final result', () {
      final r = _pipeline.score(board: _rowAndColumn(), comboStreak: 2);
      var chips = 0.0, mult = 0.0;
      for (final e in r.events) {
        chips += e.chipsDelta;
        mult = (mult + e.multDelta) * e.multFactor;
        expect(e.totalChips, chips);
        expect(e.totalMult, mult);
      }
      expect(chips, r.totalChips);
      expect(mult, r.totalMult);
    });
  });
}
