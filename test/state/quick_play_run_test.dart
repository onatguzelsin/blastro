import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

RunNotifier _quick(ProviderContainer c, {int seed = 5}) =>
    c.read(runProvider.notifier)..startQuickPlay(seed);

void main() {
  group('Quick Play starts straight on the board', () {
    test('playing at once: no Blind Select, no shop, no deck picker', () {
      final c = _container();
      _quick(c);
      final s = c.read(runProvider);
      expect(s.status, RunStatus.playing);
      expect(s.mode, RunMode.quickPlay);
      expect(s.deckId, 'deck_quick_play');
      expect(s.shop, isNull);
      expect(s.boss, isNull);
    });

    test('10 trays and 6 discards, a 4-piece tray, no bankroll', () {
      final c = _container();
      _quick(c);
      final s = c.read(runProvider);
      expect([s.traysRemaining, s.discards], [10, 6]);
      expect(s.tray.length, 4);
      expect(s.tray.every((p) => p != null), isTrue);
      expect(s.unplaced.length, 4);
      expect(s.gold, 0);
    });

    test('the 5-joker loadout is already equipped, in order', () {
      final c = _container();
      _quick(c);
      expect(c.read(runProvider).jokers.map((j) => j.id), QuickPlay.loadoutIds);
    });

    test('the bag deals 4 at a time: 4 pieces are already out of 24', () {
      final c = _container();
      final n = _quick(c);
      expect(n.bagRemaining.length, 20);
    });

    test('a normal run is unchanged: 3-piece tray, 5 trays, 3 discards', () {
      final c = _container();
      c.read(runProvider.notifier).newRun(5);
      final s = c.read(runProvider);
      expect(s.mode, RunMode.normal);
      expect(s.tray.length, 3);
      expect([s.traysRemaining, s.discards], [5, 3]);
      expect(s.jokers, isEmpty);
    });

    test('same seed, same Quick Play start', () {
      List<String?> ids(int seed) {
        final c = _container();
        _quick(c, seed: seed);
        return c.read(runProvider).tray.map((p) => p?.id).toList();
      }

      expect(ids(9), ids(9));
    });
  });

  test('the standard deck constants are untouched by Quick Play', () {
    expect(StarterDecks.standard.traysPerBlind, 5);
    expect(StarterDecks.standard.discardsPerBlind, 3);
  });
}
