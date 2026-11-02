import 'dart:convert';

import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_state_codec.dart';
import 'package:blastro/state/run_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RunPersistence> _store() async {
  SharedPreferences.setMockInitialValues({});
  return RunPersistence(await SharedPreferences.getInstance());
}

ProviderContainer _container(RunPersistence? store, {SavedRun? saved}) {
  final c = ProviderContainer(
    overrides: [
      runPersistenceProvider.overrideWithValue(store),
      savedRunProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Map<String, dynamic> _rawSave(SharedPreferences prefs) =>
    jsonDecode(prefs.getString(RunPersistence.key)!) as Map<String, dynamic>;

void main() {
  group('the deck id is saved with the run', () {
    for (final d in StarterDecks.all) {
      test(d.name, () async {
        final store = await _store();
        final prefs = await SharedPreferences.getInstance();
        final c = _container(store);
        c.read(runProvider.notifier).startRun(5, d);
        expect(_rawSave(prefs)['deck'], d.id);
        final loaded = store.load()!.state;
        expect(loaded.deckId, d.id);
        expect(loaded.deck, same(d));
      });
    }

    test('it stays saved through every later action', () async {
      final store = await _store();
      final prefs = await SharedPreferences.getInstance();
      final c = _container(store);
      final n = c.read(runProvider.notifier)
        ..startRun(5, StarterDecks.azureArchitect)
        ..playBlind()
        ..discardTray();
      expect(_rawSave(prefs)['deck'], 'deck_azure_architect');
      n.saveNow();
      expect(store.load()!.state.traysRemaining, 6);
    });
  });

  group('older and odd saves', () {
    test('a save without a deck is the Standard Deck', () async {
      final store = await _store();
      final prefs = await SharedPreferences.getInstance();
      _container(store)
          .read(runProvider.notifier)
          .startRun(5, StarterDecks.monolithCube);
      final json = _rawSave(prefs)..remove('deck');
      await prefs.setString(RunPersistence.key, jsonEncode(json));
      final loaded = store.load()!.state;
      expect(loaded.deckId, StarterDeck.standardId);
      expect(loaded.deck, StarterDecks.standard);
    });

    test(
      'an unknown deck id falls back to Standard instead of crashing',
      () async {
        final store = await _store();
        final prefs = await SharedPreferences.getInstance();
        _container(store)
            .read(runProvider.notifier)
            .startRun(5, StarterDecks.monolithCube);
        final json = _rawSave(prefs)..['deck'] = 'deck_from_the_future';
        await prefs.setString(RunPersistence.key, jsonEncode(json));
        final saved = store.load()!;
        expect(saved.state.deck, StarterDecks.standard);
        final c = _container(null, saved: saved);
        expect(c.read(runProvider).unplaced.length, 3);
        final n = c.read(runProvider.notifier);
        expect(() {
          n.playBlind();
          n.discardTray();
        }, returnsNormally);
      },
    );
  });

  group('a restored run keeps drawing from its deck', () {
    test('Monolith: same trays as an unsaved twin, only squares', () async {
      final store = await _store();
      final a = _container(store);
      final na = a.read(runProvider.notifier)
        ..startRun(21, StarterDecks.monolithCube);
      for (var i = 0; i < 6; i++) {
        na.debugSet(a.read(runProvider).copyWith(status: RunStatus.shopping));
        na.leaveShop();
      }
      final b = _container(null, saved: store.load());
      final nb = b.read(runProvider.notifier);
      expect(
        nb.bagRemaining.map((p) => p.id),
        na.bagRemaining.map((p) => p.id),
      );
      for (var i = 0; i < 25; i++) {
        na.debugSet(a.read(runProvider).copyWith(status: RunStatus.shopping));
        nb.debugSet(b.read(runProvider).copyWith(status: RunStatus.shopping));
        na.leaveShop();
        nb.leaveShop();
        final ta = a.read(runProvider).unplaced.map((p) => p.id).toList();
        final tb = b.read(runProvider).unplaced.map((p) => p.id).toList();
        expect(tb, ta, reason: 'tray $i');
        expect(tb.every((id) => id == 'rect_2x2' || id == 'rect_3x3'), isTrue);
      }
    });

    test(
      'Chromatic: restored colors are still red or blue and match',
      () async {
        final store = await _store();
        final a = _container(store);
        final na = a.read(runProvider.notifier)
          ..startRun(8, StarterDecks.chromaticFlush);
        for (var i = 0; i < 5; i++) {
          na.debugSet(a.read(runProvider).copyWith(status: RunStatus.shopping));
          na.leaveShop();
        }
        final b = _container(null, saved: store.load());
        final nb = b.read(runProvider.notifier);
        for (var i = 0; i < 20; i++) {
          na.debugSet(a.read(runProvider).copyWith(status: RunStatus.shopping));
          nb.debugSet(b.read(runProvider).copyWith(status: RunStatus.shopping));
          na.leaveShop();
          nb.leaveShop();
          final ca = a.read(runProvider).unplaced.map((p) => p.color).toList();
          final cb = b.read(runProvider).unplaced.map((p) => p.color).toList();
          expect(cb, ca);
          expect(
            cb.every((c) => c == BlockColor.red || c == BlockColor.blue),
            isTrue,
          );
        }
      },
    );

    test('piece and board colors survive the save', () async {
      final store = await _store();
      final c = _container(store);
      final n = c.read(runProvider.notifier)
        ..startRun(3, StarterDecks.standard);
      n.playBlind();
      final s0 = c.read(runProvider);
      expect(s0.tray.every((p) => p!.color != null), isTrue);
      final loaded = store.load()!.state;
      expect(loaded.tray.map((p) => p!.color), s0.tray.map((p) => p!.color));
      n.placePiece(0, 0, 0);
      final back = store.load()!.state;
      expect(back.grid.at(0, 0)!.color, s0.tray[0]!.color);
    });
  });

  test('the Continue summary names the deck', () async {
    final c = _container(null);
    c.read(runProvider.notifier).startRun(3, StarterDecks.crimsonRecycler);
    expect(RunSummary(c.read(runProvider)).deckName, 'Crimson Recycler Deck');
  });

  test('the codec writes the deck and reads it back', () {
    final c = _container(null);
    c.read(runProvider.notifier).startRun(3, StarterDecks.azureArchitect);
    final json = RunStateCodec.encode(
      c.read(runProvider),
      BlockBag(1).snapshot(),
    );
    expect(json['deck'], 'deck_azure_architect');
    expect(RunStateCodec.decode(json).state.deckId, 'deck_azure_architect');
  });
}
