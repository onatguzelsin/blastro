import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/scoring/score_step_event.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

const _pipeline = ScoringPipeline();

HapticIntensity _of(ScoreResult r, ScoreStepKind kind) =>
    r.events.firstWhere((e) => e.kind == kind).haptic;

void main() {
  late ScoreResult result;

  setUp(() {
    final board = GridMatrix.fromAscii(['XXXXXXXX'])
      ..setCell(0, 2, const GridCell(enhancement: CellEnhancement.bonus))
      ..setCell(6, 6, const GridCell(enhancement: CellEnhancement.steel))
      ..setCell(5, 5, GridCell.plain);
    result = _pipeline.score(
      board: board,
      comboStreak: 1,
      jokers: [
        JokerRegistry.byId('joker_plain').joker,
        JokerRegistry.byId('joker_amplifier').joker,
      ],
    );
  });

  test('geometry steps do not vibrate', () {
    expect(_of(result, ScoreStepKind.archetypeBase), HapticIntensity.none);
    expect(_of(result, ScoreStepKind.comboStreak), HapticIntensity.none);
  });

  test('Phase 2: plain cell chips are light, enhancements are medium', () {
    expect(_of(result, ScoreStepKind.cellChips), HapticIntensity.light);
    expect(_of(result, ScoreStepKind.cellEnhancement), HapticIntensity.medium);
  });

  test('XMult steps are heavy in every phase', () {
    expect(_of(result, ScoreStepKind.residueSteel), HapticIntensity.heavy);
    expect(_of(result, ScoreStepKind.jokerXMult), HapticIntensity.heavy);
  });

  test('Phase 4 and the final score are heavy', () {
    expect(_of(result, ScoreStepKind.jokerMult), HapticIntensity.heavy);
    expect(_of(result, ScoreStepKind.finalScore), HapticIntensity.heavy);
  });

  test('intensity never drops from light to a lower level phase-to-phase', () {
    final byPhase = <ScorePhase, int>{};
    for (final e in result.events) {
      final top = byPhase[e.phase] ?? 0;
      if (e.haptic.index > top) byPhase[e.phase] = e.haptic.index;
    }
    expect(byPhase[ScorePhase.clearedCells]!, lessThanOrEqualTo(3));
    expect(byPhase[ScorePhase.jokers], HapticIntensity.heavy.index);
    expect(
      byPhase[ScorePhase.clearedCells]!,
      lessThanOrEqualTo(byPhase[ScorePhase.jokers]!),
    );
  });
}
