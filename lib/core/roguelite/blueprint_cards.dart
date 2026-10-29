import '../scoring/clear_archetypes.dart';
import 'consumables.dart';

const _labels = {
  ClearArchetype.single: 'Single',
  ClearArchetype.parallelDouble: 'Parallel Double',
  ClearArchetype.crossClear: 'Cross Clear',
  ClearArchetype.triple: 'Triple',
  ClearArchetype.doubleCross: 'Double Cross',
  ClearArchetype.quad: 'Quad',
  ClearArchetype.zone3x3: 'Zone 3x3',
  ClearArchetype.penta: 'Penta',
  ClearArchetype.hexa: 'Hexa',
  ClearArchetype.cleanSweep: 'Clean Sweep',
};

/// The 10 Architectural Blueprint (Planet) cards, one per clear archetype.
final List<BlueprintCard> blueprintCards = [
  for (final a in ClearArchetype.values)
    BlueprintCard(
      id: 'blueprint_${a.name}',
      name: 'Blueprint: ${_labels[a]}',
      description: '+1 level for ${_labels[a]} clears.',
      archetype: a,
    ),
];
