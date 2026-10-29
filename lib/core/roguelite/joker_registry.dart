import 'joker_catalog_scoring.dart';
import 'joker_catalog_utility.dart';
import 'joker_effects.dart';

enum JokerRarity {
  common(4),
  uncommon(6),
  rare(8);

  const JokerRarity(this.price);

  /// Shop price in dollars.
  final int price;
}

/// A joker plus its display data.
class JokerDef {
  const JokerDef({
    required this.joker,
    required this.name,
    required this.rarity,
    required this.short,
    required this.description,
  });

  final Joker joker;
  final String name;
  final JokerRarity rarity;

  /// Card text, e.g. `+4 Mult`.
  final String short;
  final String description;

  String get id => joker.id;
  int get price => rarity.price;
  int get sellValue => price ~/ 2;
}

/// All 20 core jokers. Saves store ids only; behaviour is looked up here.
abstract final class JokerRegistry {
  static final List<JokerDef> all = List.unmodifiable([
    ...scoringJokers,
    ...utilityJokers,
  ]);

  static final Map<String, JokerDef> _byId = {for (final d in all) d.id: d};

  static JokerDef? maybeById(String id) => _byId[id];

  static JokerDef byId(String id) {
    final def = _byId[id];
    if (def == null) throw ArgumentError('Unknown joker: $id');
    return def;
  }
}
