import '../polyomino/block_color.dart';
import '../polyomino/polyomino_catalog.dart';
import '../polyomino/polyomino_shape.dart';

/// A Balatro-style starting inventory: which pieces the Block Bag holds, which
/// colors they are dealt in, and how many trays and discards every blind
/// starts with. Jokers and vouchers add on top of these base numbers.
class StarterDeck {
  const StarterDeck({
    required this.id,
    required this.name,
    required this.nameTr,
    required this.description,
    required this.pool,
    this.colors = BlockColor.values,
    this.traysPerBlind = defaultTrays,
    this.discardsPerBlind = defaultDiscards,
  });

  /// The Standard Deck's id, also what saves without a deck fall back to.
  static const String standardId = 'deck_standard';

  static const int defaultTrays = 5;
  static const int defaultDiscards = 3;

  final String id;
  final String name;

  /// The Turkish name, shown as a subtitle.
  final String nameTr;

  /// The deck's rule, in one or two sentences.
  final String description;

  /// What the bag is refilled with. May hold duplicates (Monolith Cube).
  final List<Polyomino> pool;

  /// The colors pieces can be dealt in.
  final List<BlockColor> colors;
  final int traysPerBlind;
  final int discardsPerBlind;

  /// Each distinct shape in the pool, once.
  List<Polyomino> get shapes {
    final seen = <String>{};
    return [
      for (final p in pool)
        if (seen.add(p.id)) p,
    ];
  }
}

/// The five starter decks. Every deck is unlocked from the start.
abstract final class StarterDecks {
  static final standard = StarterDeck(
    id: StarterDeck.standardId,
    name: 'Standard Deck',
    nameTr: 'Standart Deste',
    description:
        'The balanced classic: all 24 shapes in four colors, '
        '5 trays and 3 discards every blind.',
    pool: PolyominoCatalog.all,
  );

  /// 16 of the 2x2 and 8 of the 3x3: 24 pieces, two squares to every cube.
  static final monolithCube = StarterDeck(
    id: 'deck_monolith_cube',
    name: 'Monolith Cube Deck',
    nameTr: 'Küp Envanteri',
    description:
        'The bag holds ONLY 2x2 and 3x3 squares. Dense, heavy and perfect '
        'for square and heavy-piece jokers, but unforgiving to fit.',
    pool: [
      for (var i = 0; i < 16; i++) PolyominoCatalog.byId('rect_2x2'),
      for (var i = 0; i < 8; i++) PolyominoCatalog.byId('rect_3x3'),
    ],
  );

  static final crimsonRecycler = StarterDeck(
    id: 'deck_crimson_recycler',
    name: 'Crimson Recycler Deck',
    nameTr: 'Geri Dönüşüm Destesi',
    description: '+1 discard every blind: you start each one with 4 discards.',
    pool: PolyominoCatalog.all,
    discardsPerBlind: StarterDeck.defaultDiscards + 1,
  );

  static final azureArchitect = StarterDeck(
    id: 'deck_azure_architect',
    name: 'Azure Architect Deck',
    nameTr: 'Mimar Destesi',
    description: '+1 tray every blind: you start each one with 6 trays.',
    pool: PolyominoCatalog.all,
    traysPerBlind: StarterDeck.defaultTrays + 1,
  );

  static final chromaticFlush = StarterDeck(
    id: 'deck_chromatic_flush',
    name: 'Chromatic Flush Deck',
    nameTr: 'İkili Renk Destesi',
    description:
        'Blocks come in only Red and Blue instead of four colors, so '
        'color jokers like Red Rush and Blue Tide fire far more often.',
    pool: PolyominoCatalog.all,
    colors: [BlockColor.red, BlockColor.blue],
  );

  /// The Quick Play deck: Standard shapes and colors with DOUBLE the starting
  /// trays (10) and discards (6). It is not offered in the deck picker.
  static final quickPlay = StarterDeck(
    id: 'deck_quick_play',
    name: 'Quick Play',
    nameTr: 'Hızlı Oyun',
    description: 'Endless arcade: 10 trays, 6 discards, 4-piece trays.',
    pool: PolyominoCatalog.all,
    traysPerBlind: StarterDeck.defaultTrays * 2,
    discardsPerBlind: StarterDeck.defaultDiscards * 2,
  );

  /// The five decks you can pick for a normal run.
  static final List<StarterDeck> all = List.unmodifiable([
    standard,
    monolithCube,
    crimsonRecycler,
    azureArchitect,
    chromaticFlush,
  ]);

  static StarterDeck? maybeById(String id) {
    for (final d in [...all, quickPlay]) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// An unknown id (an older or newer save) falls back to the Standard Deck.
  static StarterDeck byIdOrStandard(String? id) =>
      (id == null ? null : maybeById(id)) ?? standard;
}
