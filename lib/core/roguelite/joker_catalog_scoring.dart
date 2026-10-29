import '../grid/grid_matrix.dart';
import 'joker_effects.dart';
import 'joker_hooks.dart';
import 'joker_registry.dart';

/// True if [grid] has a fully occupied 3x3 block anywhere.
bool hasSolid3x3(GridMatrix grid) {
  for (var r = 0; r <= GridMatrix.size - 3; r++) {
    for (var c = 0; c <= GridMatrix.size - 3; c++) {
      var solid = true;
      for (var dr = 0; dr < 3 && solid; dr++) {
        for (var dc = 0; dc < 3 && solid; dc++) {
          solid = grid.isOccupied(r + dr, c + dc);
        }
      }
      if (solid) return true;
    }
  }
  return false;
}

JokerBonus _cornerstone(ResidueScanContext c) {
  final corner = (c.row == 0 || c.row == 7) && (c.col == 0 || c.col == 7);
  return corner ? const JokerBonus(chips: 20) : JokerBonus.none;
}

JokerBonus _sanctuary(MoveContext c) =>
    hasSolid3x3(c.residue) ? const JokerBonus(xMult: 2.0) : JokerBonus.none;

JokerBonus _sevenFingers(CellScoredContext c) =>
    (c.row == 6 || c.col == 6) ? const JokerBonus(chips: 7) : JokerBonus.none;

JokerBonus _heavyweight(MoveContext c) => (c.placedPiece?.dangerTier ?? 0) == 4
    ? const JokerBonus(mult: 8)
    : JokerBonus.none;

JokerBonus _comboBanker(MoveContext c) =>
    c.comboStreak > 0 ? JokerBonus(mult: 2.0 * c.comboStreak) : JokerBonus.none;

JokerBonus _crossroads(CellScoredContext c) =>
    c.isIntersection ? const JokerBonus(chips: 10) : JokerBonus.none;

JokerBonus _tidyUp(MoveContext c) => c.residue.occupiedCount <= 8
    ? const JokerBonus(xMult: 2.0)
    : JokerBonus.none;

/// Ten jokers that change how a move scores.
final List<JokerDef> scoringJokers = [
  const JokerDef(
    joker: Joker(id: 'joker_cornerstone', onResidueScanned: _cornerstone),
    name: 'Cornerstone',
    rarity: JokerRarity.common,
    short: '+20 / corner',
    description: '+20 Chips for each occupied corner cell left on the board.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_3x3_sanctuary', onMove: _sanctuary),
    name: '3x3 Sanctuary',
    rarity: JokerRarity.rare,
    short: 'x2 on 3x3',
    description: 'x2 Mult if a fully filled 3x3 block remains on the board.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_seven_fingers', onCellScored: _sevenFingers),
    name: 'Seven Fingers',
    rarity: JokerRarity.common,
    short: '+7 on line 7',
    description: '+7 Chips for each cleared cell in row or column 7.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_heavyweight', onMove: _heavyweight),
    name: 'Heavyweight',
    rarity: JokerRarity.uncommon,
    short: '+8 Mult heavy',
    description: '+8 Mult if the placed piece is danger tier 4.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_plain', mult: 4),
    name: 'Plain Joker',
    rarity: JokerRarity.common,
    short: '+4 Mult',
    description: '+4 Mult on every scoring move.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_chip_collector', chips: 30),
    name: 'Chip Collector',
    rarity: JokerRarity.common,
    short: '+30 Chips',
    description: '+30 Chips on every scoring move.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_amplifier', xMult: 1.5),
    name: 'Amplifier',
    rarity: JokerRarity.uncommon,
    short: 'x1.5',
    description: 'x1.5 Mult on every scoring move.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_combo_banker', onMove: _comboBanker),
    name: 'Combo Banker',
    rarity: JokerRarity.uncommon,
    short: '+2 / streak',
    description: '+2 Mult per level of the active combo streak.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_crossroads', onCellScored: _crossroads),
    name: 'Crossroads',
    rarity: JokerRarity.common,
    short: '+10 cross',
    description: '+10 Chips each time a Cross Clear intersection cell scores.',
  ),
  const JokerDef(
    joker: Joker(id: 'joker_tidy_up', onMove: _tidyUp),
    name: 'Tidy Up',
    rarity: JokerRarity.rare,
    short: 'x2 if tidy',
    description: 'x2 Mult if 8 or fewer cells remain after the clear.',
  ),
];
