import 'dart:math';

import 'joker_effects.dart';
import 'joker_hooks.dart';
import 'joker_registry.dart';
import 'run_modifiers.dart';

JokerBonus _grandArchitect(MoveContext c) {
  final lines = c.clears.lineCount;
  if (lines == 0) return JokerBonus.none;
  return JokerBonus(xMult: pow(1.5, lines).toDouble());
}

/// The three Legendary jokers: rare in the shop and priced from $22.
final List<JokerDef> legendaryJokers = [
  const JokerDef(
    joker: Joker(id: 'joker_singularity', xMult: 3.0),
    name: 'Singularity',
    rarity: JokerRarity.legendary,
    basePrice: 25,
    short: 'x3 Mult',
    description: 'x3 Mult on every scoring move.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_phoenix_feather',
      modifiers: RunModifiers(extraSetupMoves: 99),
    ),
    name: 'Phoenix Feather',
    rarity: JokerRarity.legendary,
    basePrice: 22,
    short: 'Combo lives',
    description:
        'Your combo never resets, no matter how many moves go without a clear.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_grand_architect',
      onMove: _grandArchitect,
      hookXMult: true,
    ),
    name: 'Grand Architect',
    rarity: JokerRarity.legendary,
    basePrice: 28,
    short: 'x1.5 / line',
    description: 'x1.5 Mult for every line the move clears (they multiply).',
  ),
];
