enum ScorePhase { geometry, clearedCells, residue, jokers }

enum ScoreStepKind {
  archetypeBase,
  comboStreak,
  cellChips,
  cellEnhancement,
  cellEdition,
  residueSteel,
  jokerCell,
  jokerResidue,
  jokerChips,
  jokerMult,
  jokerXMult,
  allClearBonus,
  finalScore,
}

/// Maps to Flutter's `HapticFeedback` in the UI layer (core stays pure Dart).
enum HapticIntensity { none, light, medium, heavy }

/// One replayable step of the scoring calculation. Deltas describe what the
/// step did; totals are the running Chips/Mult after it.
class ScoreStepEvent {
  const ScoreStepEvent({
    required this.phase,
    required this.kind,
    required this.label,
    required this.totalChips,
    required this.totalMult,
    this.chipsDelta = 0,
    this.multDelta = 0,
    this.multFactor = 1.0,
    this.flatBonus = 0,
    this.row,
    this.col,
    this.jokerIndex,
    this.haptic = HapticIntensity.none,
  });

  final ScorePhase phase;
  final ScoreStepKind kind;
  final String label;
  final double totalChips;
  final double totalMult;
  final double chipsDelta;
  final double multDelta;
  final double multFactor;
  final int flatBonus;

  /// Board cell this step belongs to (Phase 2 and 3), if any.
  final int? row;
  final int? col;

  /// Joker slot index (Phase 4), if any.
  final int? jokerIndex;
  final HapticIntensity haptic;

  @override
  String toString() =>
      'ScoreStep(${phase.name}/${kind.name} $label chips=$totalChips mult=$totalMult)';
}
