import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:flutter_test/flutter_test.dart';

BlockBag _bag(StarterDeck d, int seed) =>
    BlockBag(seed, catalog: d.pool, palette: d.colors);

void main() {
  group('the catalog', () {
    test('five decks with the agreed names', () {
      expect(StarterDecks.all.map((d) => d.name), [
        'Standard Deck',
        'Monolith Cube Deck',
        'Crimson Recycler Deck',
        'Azure Architect Deck',
        'Chromatic Flush Deck',
      ]);
      expect(StarterDecks.all.map((d) => d.nameTr), [
        'Standart Deste',
        'Küp Envanteri',
        'Geri Dönüşüm Destesi',
        'Mimar Destesi',
        'İkili Renk Destesi',
      ]);
    });

    test('unique ids, and every deck explains its rule', () {
      expect(StarterDecks.all.map((d) => d.id).toSet().length, 5);
      for (final d in StarterDecks.all) {
        expect(d.description.length, greaterThan(20), reason: d.name);
        expect(StarterDecks.maybeById(d.id), same(d));
      }
    });

    test('unknown or missing ids fall back to the Standard Deck', () {
      expect(StarterDecks.byIdOrStandard(null), StarterDecks.standard);
      expect(
        StarterDecks.byIdOrStandard('deck_from_the_future'),
        StarterDecks.standard,
      );
      expect(StarterDecks.maybeById('nope'), isNull);
      expect(StarterDecks.standard.id, StarterDeck.standardId);
    });
  });

  group('starting numbers', () {
    test('Standard: all 24 shapes, 5 trays, 3 discards, 4 colors', () {
      final d = StarterDecks.standard;
      expect(d.pool.map((p) => p.id), PolyominoCatalog.all.map((p) => p.id));
      expect(d.pool.length, 24);
      expect([d.traysPerBlind, d.discardsPerBlind], [5, 3]);
      expect(d.colors, BlockColor.values);
    });

    test('Crimson Recycler: +1 discard (4), nothing else changes', () {
      final d = StarterDecks.crimsonRecycler;
      expect([d.traysPerBlind, d.discardsPerBlind], [5, 4]);
      expect(d.pool.length, 24);
      expect(d.colors.length, 4);
    });

    test('Azure Architect: +1 tray (6), nothing else changes', () {
      final d = StarterDecks.azureArchitect;
      expect([d.traysPerBlind, d.discardsPerBlind], [6, 3]);
      expect(d.pool.length, 24);
      expect(d.colors.length, 4);
    });

    test('Chromatic Flush: only Red and Blue, same shapes and numbers', () {
      final d = StarterDecks.chromaticFlush;
      expect(d.colors, [BlockColor.red, BlockColor.blue]);
      expect([d.traysPerBlind, d.discardsPerBlind], [5, 3]);
      expect(d.pool.length, 24);
    });

    test('Monolith Cube keeps the standard 5 trays and 3 discards', () {
      final d = StarterDecks.monolithCube;
      expect([d.traysPerBlind, d.discardsPerBlind], [5, 3]);
    });
  });

  group('Monolith Cube draws ONLY 2x2 and 3x3', () {
    final deck = StarterDecks.monolithCube;
    const allowed = {'rect_2x2', 'rect_3x3'};

    test('the pool is 16 of the 2x2 and 8 of the 3x3 (24 pieces)', () {
      expect(deck.pool.length, 24);
      expect(deck.pool.where((p) => p.id == 'rect_2x2').length, 16);
      expect(deck.pool.where((p) => p.id == 'rect_3x3').length, 8);
      expect(deck.shapes.map((p) => p.id), ['rect_2x2', 'rect_3x3']);
    });

    test('1,000 trays across many reshuffles: never any other shape', () {
      for (final seed in [1, 7, 42, 2024]) {
        final bag = _bag(deck, seed);
        for (var i = 0; i < 1000; i++) {
          for (final p in bag.drawTray()) {
            expect(allowed, contains(p.id), reason: 'seed $seed tray $i');
          }
        }
      }
    });

    test('the bag only ever holds those two shapes', () {
      final bag = _bag(deck, 5);
      expect(bag.remaining.map((p) => p.id).toSet(), allowed);
      for (var i = 0; i < 40; i++) {
        bag.drawTray();
        expect(bag.remaining.every((p) => allowed.contains(p.id)), isTrue);
      }
    });

    test('every full bag (8 trays) deals exactly 16 squares and 8 cubes', () {
      final bag = _bag(deck, 99);
      for (var cycle = 0; cycle < 20; cycle++) {
        final ids = [
          for (var t = 0; t < 8; t++) ...bag.drawTray().map((p) => p.id),
        ];
        expect(
          ids.where((i) => i == 'rect_2x2').length,
          16,
          reason: 'cycle $cycle',
        );
        expect(ids.where((i) => i == 'rect_3x3').length, 8);
      }
    });

    test('the dealt pieces really are 2x2 and 3x3 blocks', () {
      final bag = _bag(deck, 3);
      final seen = <int>{};
      for (var i = 0; i < 100; i++) {
        for (final p in bag.drawTray()) {
          expect(p.width, p.height);
          seen.add(p.cellCount);
        }
      }
      expect(seen, {4, 9});
    });

    test('the heavy 3x3 is a danger-tier-4 piece (Heavyweight food)', () {
      final cube = deck.pool.firstWhere((p) => p.id == 'rect_3x3');
      expect(cube.dangerTier, 4);
    });

    test('other decks still deal all kinds of shapes', () {
      final bag = _bag(StarterDecks.standard, 3);
      final ids = <String>{};
      for (var i = 0; i < 40; i++) {
        ids.addAll(bag.drawTray().map((p) => p.id));
      }
      expect(ids.length, 24);
    });

    test('a saved Monolith bag restores and keeps dealing only squares', () {
      final bag = _bag(deck, 11);
      for (var i = 0; i < 9; i++) {
        bag.drawTray();
      }
      final snap = BlockBagSnapshot.fromJson(bag.snapshot().toJson());
      final restored = BlockBag.restore(
        snap,
        catalog: deck.pool,
        palette: deck.colors,
      );
      for (var i = 0; i < 30; i++) {
        final a = bag.drawTray();
        final b = restored.drawTray();
        expect(b.map((p) => p.id), a.map((p) => p.id));
        expect(b.every((p) => allowed.contains(p.id)), isTrue);
      }
    });
  });
}
