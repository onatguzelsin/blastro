import '../grid/grid_cell.dart';
import 'consumables.dart';

/// The 10 Chisel (Tarot) cards. Each edits up to 2 random occupied cells
/// (Demolish removes up to 3).
const List<ChiselCard> chiselCards = [
  ChiselCard(
    id: 'chisel_bonus',
    name: 'Chisel: Bonus',
    description: 'Make 2 random cells Bonus (+30 Chips).',
    kind: ChiselKind.enhance,
    enhancement: CellEnhancement.bonus,
  ),
  ChiselCard(
    id: 'chisel_mult',
    name: 'Chisel: Mult',
    description: 'Make 2 random cells Mult (+4 Mult).',
    kind: ChiselKind.enhance,
    enhancement: CellEnhancement.mult,
  ),
  ChiselCard(
    id: 'chisel_glass',
    name: 'Chisel: Glass',
    description: 'Make 2 random cells Glass (x2 Mult).',
    kind: ChiselKind.enhance,
    enhancement: CellEnhancement.glass,
  ),
  ChiselCard(
    id: 'chisel_lucky',
    name: 'Chisel: Lucky',
    description: 'Make 2 random cells Lucky (1 in 5: +20 Mult).',
    kind: ChiselKind.enhance,
    enhancement: CellEnhancement.lucky,
  ),
  ChiselCard(
    id: 'chisel_steel',
    name: 'Chisel: Steel',
    description: 'Make 2 random cells Steel (x1.5 as residue).',
    kind: ChiselKind.enhance,
    enhancement: CellEnhancement.steel,
  ),
  ChiselCard(
    id: 'chisel_foil',
    name: 'Chisel: Foil',
    description: 'Give 2 random cells Foil (+50 Chips).',
    kind: ChiselKind.edition,
    edition: CellEdition.foil,
  ),
  ChiselCard(
    id: 'chisel_holo',
    name: 'Chisel: Holo',
    description: 'Give 2 random cells Holo (+10 Mult).',
    kind: ChiselKind.edition,
    edition: CellEdition.holo,
  ),
  ChiselCard(
    id: 'chisel_polychrome',
    name: 'Chisel: Polychrome',
    description: 'Give 2 random cells Polychrome (x1.5 Mult).',
    kind: ChiselKind.edition,
    edition: CellEdition.polychrome,
  ),
  ChiselCard(
    id: 'chisel_red_seal',
    name: 'Chisel: Red Seal',
    description: 'Give 2 random cells a Red Seal (retrigger).',
    kind: ChiselKind.seal,
  ),
  ChiselCard(
    id: 'chisel_demolish',
    name: 'Chisel: Demolish',
    description: 'Remove 3 random cells from the board.',
    kind: ChiselKind.demolish,
    targets: 3,
  ),
];
