import 'joker_effects.dart';

/// Run-wide rule changes granted by the joker bar.
class RunModifiers {
  const RunModifiers({
    this.rotation = false,
    this.extraSetupMoves = 0,
    this.extraDiscards = 0,
    this.extraTrays = 0,
    this.cashOutBonus = 0,
    this.luckyAlways = false,
    this.steelMultiplier = defaultSteelMultiplier,
  });

  static const double defaultSteelMultiplier = 1.5;
  static const RunModifiers none = RunModifiers();

  /// Aggregates every joker on the bar (additive, OR, or max as fits).
  factory RunModifiers.fromJokers(List<Joker> jokers) {
    var out = none;
    for (final j in jokers) {
      final m = j.modifiers;
      out = RunModifiers(
        rotation: out.rotation || m.rotation,
        extraSetupMoves: out.extraSetupMoves + m.extraSetupMoves,
        extraDiscards: out.extraDiscards + m.extraDiscards,
        extraTrays: out.extraTrays + m.extraTrays,
        cashOutBonus: out.cashOutBonus + m.cashOutBonus,
        luckyAlways: out.luckyAlways || m.luckyAlways,
        steelMultiplier: m.steelMultiplier > out.steelMultiplier
            ? m.steelMultiplier
            : out.steelMultiplier,
      );
    }
    return out;
  }

  /// Tray pieces can be rotated (Gyroscope).
  final bool rotation;

  /// Extra non-clearing placements the combo window survives.
  final int extraSetupMoves;
  final int extraDiscards;
  final int extraTrays;
  final int cashOutBonus;

  /// Lucky cells always trigger.
  final bool luckyAlways;

  /// Mult factor for Steel residue cells (Baron of Steel raises it).
  final double steelMultiplier;
}
