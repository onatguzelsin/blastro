import 'dart:convert';

import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Env {
  _Env(this.prefs, this.store);

  final SharedPreferences prefs;
  final RunPersistence store;

  String? get regular => prefs.getString(RunPersistence.key);
  String? get quick => prefs.getString(RunPersistence.quickPlayKey);

  ProviderContainer container({SavedRun? saved}) {
    final c = ProviderContainer(
      overrides: [
        runPersistenceProvider.overrideWithValue(store),
        savedRunProvider.overrideWithValue(saved),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }
}

Future<_Env> _env([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return _Env(prefs, RunPersistence(prefs));
}

void main() {
  group('switching between the two runs', () {
    test(
      'Continue after Quick Play brings the normal run back intact',
      () async {
        final env = await _env();
        final a = env.container();
        final na = a.read(runProvider.notifier)
          ..startRun(7, StarterDecks.azureArchitect);
        na.playBlind();
        na.placePiece(0, 0, 0);
        final normal = a.read(runProvider);
        na.startQuickPlay(3);

        final b = env.container();
        final nb = b.read(runProvider.notifier);
        nb.resumeRun(env.store.load()!);
        final s = b.read(runProvider);
        expect(s.mode, RunMode.normal);
        expect(s.deckId, 'deck_azure_architect');
        expect(s.grid.toJson(), normal.grid.toJson());
        expect(s.tray.length, 3);
        // And it keeps saving to ITS slot.
        final quick = env.quick;
        nb.placePiece(1, 3, 3);
        expect(env.quick, quick);
        expect(jsonDecode(env.regular!)['placements'], 2);
      },
    );

    test('resuming Quick Play restores 4-piece trays and its jokers', () async {
      final env = await _env();
      env.container().read(runProvider.notifier).startQuickPlay(11);
      final b = env.container();
      b
          .read(runProvider.notifier)
          .resumeRun(env.store.load(RunMode.quickPlay)!);
      final s = b.read(runProvider);
      expect(s.mode, RunMode.quickPlay);
      expect(s.tray.length, 4);
      expect(s.jokers.map((j) => j.id), QuickPlay.loadoutIds);
      expect([s.traysRemaining, s.discards], [10, 6]);
    });

    test(
      'a resumed Quick Play bag deals the same 4-piece trays as the original',
      () async {
        final env = await _env();
        final a = env.container();
        final na = a.read(runProvider.notifier)..startQuickPlay(11);

        // Finish a tray: the last piece placed makes the bag deal a new one.
        void finishTray(ProviderContainer c, RunNotifier n) {
          n.debugSet(
            c
                .read(runProvider)
                .copyWith(
                  grid: GridMatrix(),
                  tray: [PolyominoCatalog.byId('dot'), null, null, null],
                ),
          );
          n.placePiece(0, 4, 4);
        }

        for (var i = 0; i < 4; i++) {
          finishTray(a, na);
        }
        final b = env.container();
        final nb = b.read(runProvider.notifier)
          ..resumeRun(env.store.load(RunMode.quickPlay)!);
        expect(
          nb.bagRemaining.map((p) => p.id),
          na.bagRemaining.map((p) => p.id),
        );
        for (var i = 0; i < 6; i++) {
          finishTray(a, na);
          finishTray(b, nb);
          final ta = a.read(runProvider).tray;
          final tb = b.read(runProvider).tray;
          expect(tb.length, 4);
          expect(tb.map((p) => p?.id), ta.map((p) => p?.id), reason: 'tray $i');
          expect(tb.map((p) => p?.color), ta.map((p) => p?.color));
        }
      },
    );
  });
}
