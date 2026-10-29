import 'dart:math';

/// A Boss Blind modifier. Every flag is a rule the engine enforces.
class BossBlind {
  const BossBlind({
    required this.id,
    required this.name,
    required this.description,
    this.targetMultiplier = 2.0,
    this.fixedTrays,
    this.noDiscards = false,
    this.halveBase = false,
    this.disableResidue = false,
    this.ignoreCellEffects = false,
    this.oncePerArchetype = false,
    this.firstArchetypeOnly = false,
    this.halveXMult = false,
    this.goldLossPerClear = 0,
    this.finisher = false,
  });

  final String id;
  final String name;
  final String description;

  /// Multiplies the ante's base target (the standard Boss is 2x).
  final double targetMultiplier;

  /// Overrides the number of trays for the blind.
  final int? fixedTrays;
  final bool noDiscards;

  /// Archetype base Chips and Mult are halved.
  final bool halveBase;

  /// Phase 3 residue scan is skipped.
  final bool disableResidue;

  /// Enhancements and editions do nothing.
  final bool ignoreCellEffects;

  /// An archetype that already scored this blind scores 0.
  final bool oncePerArchetype;

  /// Only the first archetype scored this blind may score again.
  final bool firstArchetypeOnly;

  /// Every joker XMult is halved (x2 becomes x1.5).
  final bool halveXMult;

  /// Cash lost on each clearing placement.
  final int goldLossPerClear;

  /// Reserved for the Ante 8 Finisher (and every 8th Endless ante).
  final bool finisher;

  /// Whether [archetypeName] scores given the archetypes that already scored
  /// this blind (in order).
  bool allowsArchetype(String archetypeName, List<String> used) {
    if (oncePerArchetype && used.contains(archetypeName)) return false;
    if (firstArchetypeOnly && used.isNotEmpty && used.first != archetypeName) {
      return false;
    }
    return true;
  }
}

abstract final class BossRegistry {
  static const wall = BossBlind(
    id: 'boss_wall',
    name: 'The Wall',
    description: 'Target is 4x the ante base',
    targetMultiplier: 4.0,
  );
  static const needle = BossBlind(
    id: 'boss_needle',
    name: 'The Needle',
    description: 'Only 2 trays',
    fixedTrays: 2,
  );
  static const water = BossBlind(
    id: 'boss_water',
    name: 'The Water',
    description: 'Start with 0 discards',
    noDiscards: true,
  );
  static const flint = BossBlind(
    id: 'boss_flint',
    name: 'The Flint',
    description: 'Base Chips and Mult are halved',
    halveBase: true,
  );
  static const eye = BossBlind(
    id: 'boss_eye',
    name: 'The Eye',
    description: 'Each clear type scores only once',
    oncePerArchetype: true,
  );
  static const pillar = BossBlind(
    id: 'boss_pillar',
    name: 'The Pillar',
    description: 'Board residue is not scored',
    disableResidue: true,
  );
  static const violetVessel = BossBlind(
    id: 'boss_violet_vessel',
    name: 'Violet Vessel',
    description: 'Finisher: joker XMult is halved',
    halveXMult: true,
    finisher: true,
  );
  static const window = BossBlind(
    id: 'boss_window',
    name: 'The Window',
    description: 'Enhancements and editions do nothing',
    ignoreCellEffects: true,
  );
  static const mouth = BossBlind(
    id: 'boss_mouth',
    name: 'The Mouth',
    description: 'Only the first clear type scores',
    firstArchetypeOnly: true,
  );
  static const tooth = BossBlind(
    id: 'boss_tooth',
    name: 'The Tooth',
    description: 'Lose \$1 per clearing placement',
    goldLossPerClear: 1,
  );

  static const List<BossBlind> all = [
    wall,
    needle,
    water,
    flint,
    eye,
    pillar,
    violetVessel,
    window,
    mouth,
    tooth,
  ];

  static BossBlind byId(String id) => all.firstWhere(
    (b) => b.id == id,
    orElse: () => throw ArgumentError('Unknown boss: $id'),
  );

  /// Every 8th ante is the Finisher; other antes draw a seeded regular boss.
  static BossBlind pick(int ante, int seed) {
    if (ante % 8 == 0) return violetVessel;
    final regular = all.where((b) => !b.finisher).toList();
    return regular[Random(seed * 31 + ante).nextInt(regular.length)];
  }
}
