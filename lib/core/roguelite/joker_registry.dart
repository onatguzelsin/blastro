import 'joker_catalog_color.dart';
import 'joker_catalog_legendary.dart';
import 'joker_catalog_scoring.dart';
import 'joker_catalog_utility.dart';
import 'joker_effects.dart';

/// Rarity tiers. Each has a base shop price range (before Ante inflation)
/// and a weight for how often it shows up in a shop.
enum JokerRarity {
  common(minPrice: 6, maxPrice: 7, weight: 55),
  uncommon(minPrice: 9, maxPrice: 11, weight: 30),
  rare(minPrice: 14, maxPrice: 16, weight: 12),
  legendary(minPrice: 22, maxPrice: 30, weight: 3);

  const JokerRarity({
    required this.minPrice,
    required this.maxPrice,
    required this.weight,
  });

  final int minPrice;
  final int maxPrice;
  final int weight;
}

/// A joker plus its display data.
class JokerDef {
  const JokerDef({
    required this.joker,
    required this.name,
    required this.rarity,
    required this.basePrice,
    required this.short,
    required this.description,
  });

  final Joker joker;
  final String name;
  final JokerRarity rarity;

  /// Shop price at Ante 1, inside the rarity's range.
  final int basePrice;

  /// Card text, e.g. `+4 Mult`.
  final String short;
  final String description;

  String get id => joker.id;

  /// Selling returns half the BASE price, so inflation can't be farmed.
  int get sellValue => basePrice ~/ 2;
}

/// All 25 jokers (20 core + 3 legendary + 2 color). Saves store ids only; behaviour is looked up here.
abstract final class JokerRegistry {
  static final List<JokerDef> all = List.unmodifiable([
    ...scoringJokers,
    ...utilityJokers,
    ...legendaryJokers,
    ...colorJokers,
  ]);

  static final Map<String, JokerDef> _byId = {for (final d in all) d.id: d};

  static JokerDef? maybeById(String id) => _byId[id];

  static JokerDef byId(String id) {
    final def = _byId[id];
    if (def == null) throw ArgumentError('Unknown joker: $id');
    return def;
  }
}
