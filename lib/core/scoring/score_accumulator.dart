import 'score_step_event.dart';

/// Running Chips/Mult plus the ordered event log. Every mutation goes
/// through [add], which applies `+chips`, `+mult`, then `xMult` and records
/// the step.
class ScoreAccumulator {
  ScoreAccumulator({this.chips = 0, this.mult = 0});

  double chips;
  double mult;
  int flatBonus = 0;
  final List<ScoreStepEvent> events = [];

  /// `(chips * mult).floor() + flatBonus`.
  int get total => (chips * mult).floor() + flatBonus;

  void add({
    required ScorePhase phase,
    required ScoreStepKind kind,
    required String label,
    double addChips = 0,
    double addMult = 0,
    double xMult = 1.0,
    int flat = 0,
    int? row,
    int? col,
    int? jokerIndex,
  }) {
    chips += addChips;
    mult = (mult + addMult) * xMult;
    flatBonus += flat;
    events.add(
      ScoreStepEvent(
        phase: phase,
        kind: kind,
        label: label,
        totalChips: chips,
        totalMult: mult,
        chipsDelta: addChips,
        multDelta: addMult,
        multFactor: xMult,
        flatBonus: flat,
        row: row,
        col: col,
        jokerIndex: jokerIndex,
        haptic: _hapticFor(phase, kind, xMult),
      ),
    );
  }

  /// Escalating haptics across the chain: Phase 2 cell chips are light,
  /// other Phase 2 steps medium, Phase 3 medium, Phase 4 heavy; any XMult
  /// and the final score are always heavy.
  static HapticIntensity _hapticFor(
    ScorePhase phase,
    ScoreStepKind kind,
    double xMult,
  ) {
    if (phase == ScorePhase.geometry) return HapticIntensity.none;
    if (xMult > 1.0 || kind == ScoreStepKind.finalScore) {
      return HapticIntensity.heavy;
    }
    return switch (phase) {
      ScorePhase.clearedCells =>
        kind == ScoreStepKind.cellChips
            ? HapticIntensity.light
            : HapticIntensity.medium,
      ScorePhase.residue => HapticIntensity.medium,
      _ => HapticIntensity.heavy,
    };
  }
}
