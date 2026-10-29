import '../grid/line_detector.dart';

enum ClearArchetype {
  single,
  parallelDouble,
  crossClear,
  triple,
  doubleCross,
  quad,
  zone3x3,
  penta,
  hexa,
  cleanSweep,
}

/// Base Chips/Mult for an archetype at level 1, plus per-level growth.
class ArchetypeBase {
  const ArchetypeBase(this.chips, this.mult, this.levelChips, this.levelMult);

  final int chips;
  final int mult;
  final int levelChips;
  final int levelMult;

  int chipsAt(int level) => chips + levelChips * (level - 1);
  int multAt(int level) => mult + levelMult * (level - 1);
}

abstract final class ClearArchetypes {
  /// +360 flat bonus added after Chips x Mult on a Clean Sweep.
  static const int allClearBonus = 360;

  /// Tunable balance table (placeholder values for Phase 1).
  static const Map<ClearArchetype, ArchetypeBase> base = {
    ClearArchetype.single: ArchetypeBase(10, 1, 5, 1),
    ClearArchetype.parallelDouble: ArchetypeBase(20, 2, 10, 1),
    ClearArchetype.crossClear: ArchetypeBase(25, 2, 10, 1),
    ClearArchetype.triple: ArchetypeBase(35, 3, 15, 1),
    ClearArchetype.doubleCross: ArchetypeBase(50, 4, 20, 1),
    ClearArchetype.quad: ArchetypeBase(60, 5, 20, 1),
    ClearArchetype.penta: ArchetypeBase(80, 6, 25, 2),
    ClearArchetype.zone3x3: ArchetypeBase(100, 7, 30, 2),
    ClearArchetype.hexa: ArchetypeBase(120, 8, 35, 2),
    ClearArchetype.cleanSweep: ArchetypeBase(150, 10, 40, 2),
  };

  /// Classifies a simultaneous clear. Returns `null` when nothing cleared.
  ///
  /// * 1 line -> Single; 2 parallel -> ParallelDouble; 1 row + 1 col -> Cross
  /// * 3 lines (any mix) -> Triple; 2 rows + 2 cols -> DoubleCross
  /// * other 4 lines -> Quad; 5 lines -> Penta
  /// * exactly 3 rows + 3 cols -> Zone3x3; any other 6+ lines -> Hexa
  /// * board empty after the clear -> CleanSweep (overrides all of the above)
  static ClearArchetype? classify(
    LineClears clears, {
    required bool boardEmptyAfter,
  }) {
    if (clears.isEmpty) return null;
    if (boardEmptyAfter) return ClearArchetype.cleanSweep;
    final r = clears.rows.length;
    final c = clears.cols.length;
    return switch (r + c) {
      1 => ClearArchetype.single,
      2 => r == 1 ? ClearArchetype.crossClear : ClearArchetype.parallelDouble,
      3 => ClearArchetype.triple,
      4 =>
        (r == 2 && c == 2) ? ClearArchetype.doubleCross : ClearArchetype.quad,
      5 => ClearArchetype.penta,
      _ => (r == 3 && c == 3) ? ClearArchetype.zone3x3 : ClearArchetype.hexa,
    };
  }
}
