import 'dart:convert';

import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/quick_play_records.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_state_codec.dart';
import 'package:blastro/state/run_summary.dart';
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

GridMatrix _almostRow() =>
    GridMatrix.fromAscii(['XXXXXXX.'])..setCell(7, 0, GridCell.plain);

void main() {
  group('Quick Play has its OWN save slot', () {
    test(
      'starting Quick Play leaves a saved normal run exactly as it was',
      () async {
        final env = await _env();
        final c = env.container();
        final n = c.read(runProvider.notifier)
          ..startRun(7, StarterDecks.azureArchitect);
        n.playBlind();
        final before = env.regular;
        expect(before, isNotNull);

        n.startQuickPlay(3);
        expect(env.regular, before, reason: 'normal slot untouched');
        expect(env.quick, isNotNull);
        expect(jsonDecode(env.quick!)['mode'], 'quickPlay');
        expect(jsonDecode(env.regular!)['mode'], 'normal');
      },
    );

    test(
      'playing Quick Play for a long time never changes the normal slot',
      () async {
        final env = await _env();
        final c = env.container();
        final n = c.read(runProvider.notifier)..startRun(7);
        final before = env.regular;
        n.startQuickPlay(3);
        for (var i = 0; i < 30; i++) {
          n.debugSet(
            c
                .read(runProvider)
                .copyWith(
                  grid: _almostRow(),
                  tray: [
                    PolyominoCatalog.byId('dot'),
                    PolyominoCatalog.byId('dot'),
                    null,
                    null,
                  ],
                ),
          );
          n.placePiece(0, 0, 7);
          n.discardTray();
          n.saveNow();
        }
        expect(env.regular, before);
      },
    );

    test(
      'and the other way round: a new normal run leaves Quick Play alone',
      () async {
        final env = await _env();
        final c = env.container();
        final n = c.read(runProvider.notifier)..startQuickPlay(3);
        final quick = env.quick;
        n.startRun(9);
        n.playBlind();
        expect(env.quick, quick);
        expect(env.regular, isNotNull);
      },
    );

    test(
      'load() reads the normal slot; load(quickPlay) reads the other',
      () async {
        final env = await _env();
        final c = env.container();
        final n = c.read(runProvider.notifier)..startRun(7);
        n.startQuickPlay(3);
        expect(env.store.load()!.state.mode, RunMode.normal);
        expect(
          env.store.load(RunMode.quickPlay)!.state.mode,
          RunMode.quickPlay,
        );
        expect(RunPersistence.keyFor(RunMode.normal), RunPersistence.key);
        expect(
          RunPersistence.keyFor(RunMode.quickPlay),
          RunPersistence.quickPlayKey,
        );
        expect(RunPersistence.key, isNot(RunPersistence.quickPlayKey));
      },
    );

    test('losing a normal run deletes only the normal slot', () async {
      final env = await _env();
      final c = env.container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      n.startRun(7);
      n.debugSet(c.read(runProvider).copyWith(status: RunStatus.lost));
      await env.store.save(c.read(runProvider), BlockBag(1).snapshot());
      expect(env.regular, isNull);
      expect(env.quick, isNotNull, reason: 'Quick Play survives');
    });

    test(
      'a corrupt Quick Play slot is dropped without touching the normal run',
      () async {
        final env = await _env();
        env.container().read(runProvider.notifier).startRun(7);
        final regular = env.regular;
        await env.prefs.setString(RunPersistence.quickPlayKey, '{broken');
        expect(env.store.load(RunMode.quickPlay), isNull);
        expect(env.prefs.containsKey(RunPersistence.quickPlayKey), isFalse);
        expect(env.regular, regular);
      },
    );

    test('saves from before Quick Play existed load as normal runs', () async {
      final env = await _env();
      env.container().read(runProvider.notifier).startRun(7);
      final json = jsonDecode(env.regular!) as Map<String, dynamic>
        ..remove('mode');
      await env.prefs.setString(RunPersistence.key, jsonEncode(json));
      expect(env.store.load()!.state.mode, RunMode.normal);
    });
  });

  group('the best score', () {
    test('only ever goes up, and is saved on the device', () async {
      final env = await _env();
      final c = env.container();
      final best = c.read(quickPlayBestProvider.notifier);
      expect(c.read(quickPlayBestProvider), 0);
      best.record(500);
      best.record(300);
      expect(c.read(quickPlayBestProvider), 500);
      best.record(900);
      expect(env.store.bestQuickPlayScore, 900);
      // A brand-new app session reads it back.
      expect(env.container().read(quickPlayBestProvider), 900);
    });

    test('rises live as a Quick Play run scores', () async {
      final env = await _env();
      final c = env.container();
      final n = c.read(runProvider.notifier)..startQuickPlay(3);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              grid: _almostRow(),
              tray: [PolyominoCatalog.byId('dot'), null, null, null],
            ),
      );
      n.placePiece(0, 0, 7);
      final score = c.read(runProvider).score;
      expect(score, greaterThan(0));
      expect(c.read(quickPlayBestProvider), score);
      expect(env.store.bestQuickPlayScore, score);
    });

    test('normal runs never touch it', () async {
      final env = await _env();
      final c = env.container();
      final n = c.read(runProvider.notifier)..newRun(3);
      n.debugSet(c.read(runProvider).copyWith(score: 99999));
      n.saveNow();
      expect(c.read(quickPlayBestProvider), 0);
    });
  });

  test('the Continue summary reads naturally for Quick Play', () async {
    final env = await _env();
    final c = env.container();
    c.read(runProvider.notifier).startQuickPlay(3);
    final sum = RunSummary(c.read(runProvider));
    expect(sum.headline, 'Quick Play');
    expect(sum.detail, contains('Trays 10'));
  });
}
