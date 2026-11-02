import '../polyomino/block_color.dart';
import 'joker_effects.dart';
import 'joker_hooks.dart';
import 'joker_registry.dart';

JokerBonus _redRush(CellScoredContext c) => c.cell.color == BlockColor.red
    ? const JokerBonus(mult: 1)
    : JokerBonus.none;

JokerBonus _blueTide(CellScoredContext c) => c.cell.color == BlockColor.blue
    ? const JokerBonus(chips: 8)
    : JokerBonus.none;

/// Color-synergy jokers. They shine with the Chromatic Flush Deck, where only
/// red and blue blocks appear.
final List<JokerDef> colorJokers = [
  const JokerDef(
    joker: Joker(id: 'joker_red_rush', onCellScored: _redRush),
    name: 'Red Rush',
    rarity: JokerRarity.common,
    basePrice: 6,
    short: '+1 / red',
    description: '+1 Mult for every red cell that scores in a clear.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_blue_tide', onCellScored: _blueTide),
    name: 'Blue Tide',
    rarity: JokerRarity.common,
    basePrice: 7,
    short: '+8 / blue',
    description: '+8 Chips for every blue cell that scores in a clear.',
  ),
];
