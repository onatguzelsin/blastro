import 'joker_effects.dart';
import 'joker_registry.dart';
import 'run_modifiers.dart';

/// Ten jokers that copy others or bend the run's rules.
final List<JokerDef> utilityJokers = [
  const JokerDef(
    joker: Joker(
      id: 'joker_gyroscope',
      modifiers: RunModifiers(rotation: true),
    ),
    name: 'Gyroscope',
    rarity: JokerRarity.rare,
    basePrice: 15,
    short: 'Rotate',
    description: 'Tap a tray piece to rotate it.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_streak_saver',
      modifiers: RunModifiers(extraSetupMoves: 1),
    ),
    name: 'Streak Saver',
    rarity: JokerRarity.uncommon,
    basePrice: 10,
    short: '+1 setup',
    description: 'Your combo survives 1 extra non-clearing placement.',
  ),
  const JokerDef(
    joker: Joker.blueprint(),
    name: 'Blueprint',
    rarity: JokerRarity.rare,
    basePrice: 16,
    short: 'Copy right',
    description: 'Copies the joker to its right.',
  ),
  const JokerDef(
    joker: Joker.brainstorm(),
    name: 'Brainstorm',
    rarity: JokerRarity.rare,
    basePrice: 16,
    short: 'Copy first',
    description: 'Copies the leftmost joker.',
  ),
  const JokerDef(
    joker: Joker.mime(),
    name: 'Mime',
    rarity: JokerRarity.uncommon,
    basePrice: 9,
    short: 'Retrigger',
    description: 'Retriggers board residue effects once.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_baron_of_steel',
      modifiers: RunModifiers(steelMultiplier: 2.0),
    ),
    name: 'Baron of Steel',
    rarity: JokerRarity.rare,
    basePrice: 14,
    short: 'Steel x2',
    description: 'Steel cells in the residue give x2 Mult instead of x1.5.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_lucky_charm',
      modifiers: RunModifiers(luckyAlways: true),
    ),
    name: 'Lucky Charm',
    rarity: JokerRarity.uncommon,
    basePrice: 10,
    short: 'Always lucky',
    description: 'Lucky cells always trigger.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_pocket_change',
      modifiers: RunModifiers(cashOutBonus: 2),
    ),
    name: 'Pocket Change',
    rarity: JokerRarity.common,
    basePrice: 6,
    short: '+\$2 cash out',
    description: 'Earn an extra \$2 whenever you cash out a blind.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_extra_tray',
      modifiers: RunModifiers(extraTrays: 1),
    ),
    name: 'Extra Tray',
    rarity: JokerRarity.uncommon,
    basePrice: 11,
    short: '+1 tray',
    description: '+1 tray every blind.',
  ),
  const JokerDef(
    joker: Joker(
      id: 'joker_discard_hoarder',
      modifiers: RunModifiers(extraDiscards: 1),
    ),
    name: 'Discard Hoarder',
    rarity: JokerRarity.common,
    basePrice: 7,
    short: '+1 discard',
    description: '+1 discard every blind.',
  ),
];
