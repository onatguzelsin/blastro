import 'dart:math';

import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
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
  group('Phase 1', () {
    test('no clear scores zero with no events', () {
      final r = _pipeline.score(
        board: GridMatrix.fromAscii(['XXXXXXX.']),
        comboStreak: 3,
      );
      expect(r.finalScore, 0);
      expect(r.events, isEmpty);
      expect(r.archetype, isNull);
    });

    test('streak adds to Mult; levels raise base', () {
      final board = GridMatrix.fromAscii([_row0])
        ..setCell(5, 5, GridCell.plain);
      final r = _pipeline.score(board: board, comboStreak: 3);
      final base = _chips(ClearArchetype.single) + 80;
      expect(r.totalChips, base);
      expect(r.totalMult, _mult(ClearArchetype.single) + 3);
      expect(r.finalScore, (base * r.totalMult).floor());

      final lv = _pipeline.score(
        board: board,
        comboStreak: 0,
        archetypeLevels: {ClearArchetype.single: 3},
      );
      expect(
        lv.totalChips,
        ClearArchetypes.base[ClearArchetype.single]!.chipsAt(3) + 80,
      );
    });

    test('does not mutate the input board', () {
      final board = _rowAndColumn();
      final before = board.occupiedCount;
      _pipeline.score(board: board, comboStreak: 0);
      expect(board.occupiedCount, before);
    });
  });

  group('Phase 2: Cross Clear', () {
    late ScoreResult r;
    setUp(() => r = _pipeline.score(board: _rowAndColumn(), comboStreak: 0));

    test('classified as CrossClear', () {
      expect(r.archetype, ClearArchetype.crossClear);
    });

    test('intersection (0,0) triggers TWICE; 16 cell visits total', () {
      final cells = r.events.where((e) => e.kind == ScoreStepKind.cellChips);
      expect(cells.length, 16);
      expect(cells.where((e) => e.row == 0 && e.col == 0).length, 2);
      expect(cells.where((e) => e.row == 0 && e.col == 1).length, 1);
      expect(r.totalChips, _chips(ClearArchetype.crossClear) + 160);
    });

    test('scan order: row left-to-right, then column top-to-bottom', () {
      final order = r.events
          .where((e) => e.kind == ScoreStepKind.cellChips)
          .map((e) => [e.row, e.col])
          .toList();
      expect(order.take(8).toList(), [
        for (var c = 0; c < 8; c++) [0, c],
      ]);
      expect(order.skip(8).toList(), [
        for (var i = 0; i < 8; i++) [i, 0],
      ]);
    });

    test('final score formula', () {
      expect(
        r.finalScore,
        (r.totalChips * _mult(ClearArchetype.crossClear)).floor(),
      );
    });
  });

  group('Phase 2: enhancements, editions, seals', () {
    GridMatrix withCell(GridCell cell) =>
        (GridMatrix.fromAscii([_row0])..setCell(0, 3, cell))
          ..setCell(5, 5, GridCell.plain);

    test('bonus/mult/glass/foil/holo/polychrome', () {
      double mult(GridCell c) =>
          _pipeline.score(board: withCell(c), comboStreak: 0).totalMult;
      double chips(GridCell c) =>
          _pipeline.score(board: withCell(c), comboStreak: 0).totalChips;
      final m = _mult(ClearArchetype.single);
      final c0 = _chips(ClearArchetype.single) + 80;
      expect(
        chips(const GridCell(enhancement: CellEnhancement.bonus)),
        c0 + 30,
      );
      expect(mult(const GridCell(enhancement: CellEnhancement.mult)), m + 4);
      expect(mult(const GridCell(enhancement: CellEnhancement.glass)), m * 2);
      expect(chips(const GridCell(edition: CellEdition.foil)), c0 + 50);
      expect(mult(const GridCell(edition: CellEdition.holo)), m + 10);
      expect(mult(const GridCell(edition: CellEdition.polychrome)), m * 1.5);
    });

    test('Red Seal retriggers the cell once', () {
      final r = _pipeline.score(
        board: withCell(
          const GridCell(
            seal: CellSeal.red,
            enhancement: CellEnhancement.bonus,
          ),
        ),
        comboStreak: 0,
      );
      expect(r.totalChips, _chips(ClearArchetype.single) + 70 + 2 * 40);
    });

    test('Lucky is deterministic for a seeded Random', () {
      const lucky = GridCell(enhancement: CellEnhancement.lucky);
      int run() => _pipeline
          .score(board: withCell(lucky), comboStreak: 0, rng: Random(5))
          .finalScore;
      expect(run(), run());
    });
  });
}
