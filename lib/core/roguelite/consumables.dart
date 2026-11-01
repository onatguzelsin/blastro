import 'dart:math';

import '../grid/grid_cell.dart';
import '../grid/grid_matrix.dart';
import '../scoring/clear_archetypes.dart';
import 'blueprint_cards.dart';
import 'chisel_cards.dart';

/// A single-use card. Blueprints level a clear archetype; Chisels edit the
/// board.
sealed class Consumable {
  const Consumable({
    required this.id,
    required this.name,
    required this.description,
  });

  static const int maxHeld = 2;

  /// Shop price at Ante 1: Blueprints \$5, Chisels \$6.
  int get basePrice;

  final String id;
  final String name;
  final String description;
}

/// Architectural Blueprint (Planet): +1 level for one clear archetype.
final class BlueprintCard extends Consumable {
  @override
  int get basePrice => 5;

  const BlueprintCard({
    required super.id,
    required super.name,
    required super.description,
    required this.archetype,
  });

  final ClearArchetype archetype;

  Map<ClearArchetype, int> levelUp(Map<ClearArchetype, int> levels) => {
    ...levels,
    archetype: (levels[archetype] ?? 1) + 1,
  };
}

enum ChiselKind { enhance, edition, seal, demolish }

/// Chisel (Tarot): edits up to [targets] random occupied cells.
final class ChiselCard extends Consumable {
  @override
  int get basePrice => 6;

  const ChiselCard({
    required super.id,
    required super.name,
    required super.description,
    required this.kind,
    this.enhancement,
    this.edition,
    this.targets = 2,
  });

  final ChiselKind kind;
  final CellEnhancement? enhancement;
  final CellEdition? edition;
  final int targets;

  bool canUse(GridMatrix grid) => grid.occupiedCount > 0;

  /// Returns an edited copy; [grid] is untouched. Targets are picked by [rng]
  /// so a seeded run is reproducible.
  GridMatrix apply(GridMatrix grid, Random rng) {
    final occupied = [
      for (var r = 0; r < GridMatrix.size; r++)
        for (var c = 0; c < GridMatrix.size; c++)
          if (grid.isOccupied(r, c)) (r, c),
    ]..shuffle(rng);
    final out = grid.copy();
    for (final (r, c) in occupied.take(targets)) {
      final cell = grid.at(r, c)!;
      out.setCell(r, c, switch (kind) {
        ChiselKind.enhance => cell.copyWith(enhancement: enhancement),
        ChiselKind.edition => cell.copyWith(edition: edition),
        ChiselKind.seal => cell.copyWith(seal: CellSeal.red),
        ChiselKind.demolish => null,
      });
    }
    return out;
  }
}

abstract final class ConsumableRegistry {
  static final List<Consumable> all = List.unmodifiable([
    ...blueprintCards,
    ...chiselCards,
  ]);

  static final Map<String, Consumable> _byId = {for (final c in all) c.id: c};

  static Consumable byId(String id) {
    final card = _byId[id];
    if (card == null) throw ArgumentError('Unknown consumable: $id');
    return card;
  }
}
