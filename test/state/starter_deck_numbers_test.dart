import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

RunNotifier _start(ProviderContainer c, StarterDeck d, {int seed = 7}) =>
    c.read(runProvider.notifier)..startRun(seed, d);

/// Beat the current blind, shop, and move on to the next blind's card.
void _nextBlind(ProviderContainer c, RunNotifier n) {
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(status: RunStatus.blindCleared, traysRemaining: 2),
  );
  n.collectCashOut();
  n.leaveShop();
}

int _seedWithBoss(BossBlind boss) => List.generate(
  3000,
  (i) => i,
).firstWhere((s) => BossRegistry.pick(1, s) == boss);

void main() {
  group('a run starts with its deck\'s numbers', () {
    for (final d in StarterDecks.all) {
      test(d.name, () {
        final c = _container();
        final n = _start(c, d);
        var s = c.read(runProvider);
        expect(s.deckId, d.id);
        expect(s.deck, same(d));
        expect(s.status, RunStatus.blindSelect);
        expect(
          [s.traysRemaining, s.discards],
          [d.traysPerBlind, d.discardsPerBlind],
        );
        n.playBlind();
        s = c.read(runProvider);
        expect(
          [s.traysRemaining, s.discards],
          [d.traysPerBlind, d.discardsPerBlind],
        );
      });
    }

    test('exact figures: Azure 6 trays, Recycler 4 discards, others 5 / 3', () {
      final figures = {
        for (final d in StarterDecks.all)
          d.id: () {
            final c = _container();
            _start(c, d).playBlind();
            final s = c.read(runProvider);
            return [s.traysRemaining, s.discards];
          }(),
      };
      expect(figures['deck_standard'], [5, 3]);
      expect(figures['deck_monolith_cube'], [5, 3]);
      expect(figures['deck_crimson_recycler'], [5, 4]);
      expect(figures['deck_azure_architect'], [6, 3]);
      expect(figures['deck_chromatic_flush'], [5, 3]);
    });

    test('newRun without a deck is the Standard Deck', () {
      final c = _container();
      c.read(runProvider.notifier).newRun(3);
      expect(c.read(runProvider).deckId, StarterDeck.standardId);
      expect(c.read(runProvider).traysRemaining, 5);
    });
  });

  group('the numbers apply at EVERY blind, not just the first', () {
    test('Azure Architect has 6 trays again at the next blind and ante', () {
      final c = _container();
      final n = _start(c, StarterDecks.azureArchitect);
      for (var i = 0; i < 7; i++) {
        n.playBlind();
        expect(c.read(runProvider).traysRemaining, 6, reason: 'blind #$i');
        _nextBlind(c, n);
      }
      expect(c.read(runProvider).ante, greaterThan(1));
    });

    test('Crimson Recycler has 4 discards at every blind, refilled', () {
      final c = _container();
      final n = _start(c, StarterDecks.crimsonRecycler);
      for (var i = 0; i < 5; i++) {
        n.playBlind();
        expect(c.read(runProvider).discards, 4, reason: 'blind #$i');
        n.discardTray();
        expect(c.read(runProvider).discards, 3);
        _nextBlind(c, n);
      }
    });
  });

  group('deck numbers stack with jokers and vouchers', () {
    test('Azure Architect + Extra Tray = 7 trays', () {
      final c = _container();
      final n = _start(c, StarterDecks.azureArchitect);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(jokers: [JokerRegistry.byId('joker_extra_tray').joker]),
      );
      n.playBlind();
      expect(c.read(runProvider).traysRemaining, 7);
    });

    test('Crimson Recycler + Wasteful + Discard Hoarder = 6 discards', () {
      final c = _container();
      final n = _start(c, StarterDecks.crimsonRecycler);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              vouchers: [VoucherRegistry.wasteful.id],
              jokers: [JokerRegistry.byId('joker_discard_hoarder').joker],
            ),
      );
      n.playBlind();
      expect(c.read(runProvider).discards, 6);
    });

    test(
      'Standard + the same extras is 6 trays / 5 discards (the baseline)',
      () {
        final c = _container();
        final n = _start(c, StarterDecks.standard);
        n.debugSet(
          c
              .read(runProvider)
              .copyWith(
                vouchers: [VoucherRegistry.wasteful.id],
                jokers: [
                  JokerRegistry.byId('joker_extra_tray').joker,
                  JokerRegistry.byId('joker_discard_hoarder').joker,
                ],
              ),
        );
        n.playBlind();
        expect(
          [c.read(runProvider).traysRemaining, c.read(runProvider).discards],
          [6, 5],
        );
      },
    );
  });

  group('boss rules still win', () {
    ProviderContainer atBoss(StarterDeck d, BossBlind boss) {
      final c = _container();
      final n = _start(c, d, seed: _seedWithBoss(boss));
      n.debugSet(c.read(runProvider).copyWith(blind: BlindType.boss));
      n.playBlind();
      return c;
    }

    test('The Needle caps even the 6-tray deck at 2 trays', () {
      final c = atBoss(StarterDecks.azureArchitect, BossRegistry.needle);
      expect(c.read(runProvider).traysRemaining, 2);
    });

    test('The Water removes even the Recycler\'s 4 discards', () {
      final c = atBoss(StarterDecks.crimsonRecycler, BossRegistry.water);
      expect(c.read(runProvider).discards, 0);
    });
  });
}
