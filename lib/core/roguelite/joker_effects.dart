import '../scoring/score_accumulator.dart';
import '../scoring/score_step_event.dart';
import 'joker_hooks.dart';
import 'joker_scoring_hooks.dart';
import 'run_modifiers.dart';

enum JokerCopy { none, blueprint, brainstorm }

/// A joker's scoring behaviour. Static fields apply in Phase 4; the hooks
/// add context-dependent bonuses in Phases 2, 3 and 4; [modifiers] change
/// run rules. Display data (name, price) lives in `JokerDef`.
class Joker {
  const Joker({
    required this.id,
    this.chips = 0,
    this.mult = 0,
    this.xMult = 1.0,
    this.copy = JokerCopy.none,
    this.retriggersResidue = false,
    this.hookXMult = false,
    this.modifiers = RunModifiers.none,
    this.onCellScored,
    this.onResidueScanned,
    this.onMove,
  });

  /// Copies the joker to its right.
  const Joker.blueprint()
    : this(id: 'joker_blueprint', copy: JokerCopy.blueprint);

  /// Copies the joker at index 0.
  const Joker.brainstorm()
    : this(id: 'joker_brainstorm', copy: JokerCopy.brainstorm);

  /// Retriggers Phase 3 residue effects once.
  const Joker.mime() : this(id: 'joker_mime', retriggersResidue: true);

  final String id;
  final double chips;
  final double mult;
  final double xMult;
  final JokerCopy copy;
  final bool retriggersResidue;

  /// True if an `onMove`/hook bonus can include an XMult (so Violet Vessel
  /// can mark it as debuffed without running the hook).
  final bool hookXMult;
  final RunModifiers modifiers;
  final CellScoredHook? onCellScored;
  final ResidueScannedHook? onResidueScanned;
  final MoveHook? onMove;
}

/// A bar slot together with the joker whose effect it actually produces.
class ResolvedJoker {
  const ResolvedJoker(this.slot, this.joker);

  final int slot;
  final Joker joker;
}

abstract final class JokerBar {
  /// The joker whose effect slot [index] actually produces, following
  /// Blueprint (right neighbor) and Brainstorm (index 0). Null if the copy
  /// target is missing or the chain is circular.
  static Joker? resolve(List<Joker> jokers, int index, [Set<int>? seen]) {
    final visited = seen ?? <int>{};
    if (!visited.add(index)) return null;
    final joker = jokers[index];
    return switch (joker.copy) {
      JokerCopy.none => joker,
      JokerCopy.blueprint =>
        index + 1 < jokers.length ? resolve(jokers, index + 1, visited) : null,
      JokerCopy.brainstorm => resolve(jokers, 0, visited),
    };
  }

  /// Every slot that produces an effect, left to right.
  static List<ResolvedJoker> resolved(List<Joker> jokers) => [
    for (var i = 0; i < jokers.length; i++)
      if (resolve(jokers, i) case final j?) ResolvedJoker(i, j),
  ];

  /// Number of Phase 3 residue retriggers granted by the bar (Mime).
  static int residueRetriggers(List<Joker> jokers) =>
      resolved(jokers).where((r) => r.joker.retriggersResidue).length;

  /// Phase 4: strictly left-to-right; within a joker +Chips, +Mult, XMult,
  /// then the context-dependent [Joker.onMove] bonus. [xMultScale] < 1
  /// dampens every XMult (the Violet Vessel boss).
  static void apply(
    ScoreAccumulator acc,
    List<Joker> jokers, {
    MoveContext? move,
    double xMultScale = 1.0,
  }) {
    for (final r in resolved(jokers)) {
      final effect = r.joker;
      final slot = jokers[r.slot].id;
      void step(
        ScoreStepKind kind,
        String what, {
        double chips = 0,
        double mult = 0,
        double x = 1,
      }) => acc.add(
        phase: ScorePhase.jokers,
        kind: kind,
        label: '$slot $what',
        addChips: chips,
        addMult: mult,
        xMult: x,
        jokerIndex: r.slot,
      );
      if (effect.chips != 0) {
        step(
          ScoreStepKind.jokerChips,
          '+${effect.chips} chips',
          chips: effect.chips,
        );
      }
      if (effect.mult != 0) {
        step(
          ScoreStepKind.jokerMult,
          '+${effect.mult} mult',
          mult: effect.mult,
        );
      }
      if (effect.xMult != 1.0) {
        final x = JokerScoringHooks.scaleX(effect.xMult, xMultScale);
        step(ScoreStepKind.jokerXMult, 'x$x mult', x: x);
      }
      final hook = effect.onMove;
      if (hook != null && move != null) {
        JokerScoringHooks.applyBonus(
          acc,
          hook(move),
          phase: ScorePhase.jokers,
          label: slot,
          slot: r.slot,
          xMultScale: xMultScale,
        );
      }
    }
  }
}
