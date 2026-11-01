import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _container([RunPersistence? store]) {
  final c = ProviderContainer(
    overrides: [runPersistenceProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('starting a run', () {
    test('startRun parks the run on Ante 1 Small Blind select', () {
      final c = _container();
      c.read(runProvider.notifier).startRun(5);
      final s = c.read(runProvider);
      expect(
        [s.status, s.ante, s.blind],
        [RunStatus.blindSelect, 1, BlindType.small],
      );
      expect(s.tray.whereType<Object>().length, 3);
    });

    test('nothing can be placed from the Blind Select screen', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startRun(5);
      expect(n.placePiece(0, 0, 0), isFalse);
      expect(n.discardTray, returnsNormally);
      expect(c.read(runProvider).discards, RunState.discardsPerBlind);
    });

    test('Play Blind starts the board', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..startRun(5);
      n.playBlind();
      final s = c.read(runProvider);
      expect(s.status, RunStatus.playing);
      expect(s.traysRemaining, RunState.traysPerBlind);
      expect(n.placePiece(0, 0, 0), isTrue);
    });

    test('Play Blind only works from the hub', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(5);
      final before = c.read(runProvider).tray.map((p) => p?.id).toList();
      n.playBlind();
      expect(c.read(runProvider).tray.map((p) => p?.id).toList(), before);
    });
  });

  group('saving the hub', () {
    test('Blind Select and skipped blinds survive a relaunch', () async {
      SharedPreferences.setMockInitialValues({});
      final store = RunPersistence(await SharedPreferences.getInstance());
      final c = _container(store);
      final n = c.read(runProvider.notifier)..startRun(9);
      n.skipBlind();
      final saved = store.load()!.state;
      expect(
        [saved.status, saved.blind, saved.skipped],
        [
          RunStatus.blindSelect,
          BlindType.big,
          [BlindType.small],
        ],
      );
    });

    test('the untouched placeholder run is never saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = RunPersistence(await SharedPreferences.getInstance());
      final c = _container(store);
      c.read(runProvider.notifier).saveNow();
      expect(store.load(), isNull);
    });
  });

  group('RunSummary', () {
    test('headline and detail for each stage', () {
      final c = _container();
      final n = c.read(runProvider.notifier)..newRun(1);
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(ante: 3, blind: BlindType.big, score: 12, gold: 9),
      );
      var sum = RunSummary(c.read(runProvider));
      expect(sum.headline, 'Ante 3 · Big Blind');
      expect(sum.detail, 'Score 12 / 3000 · \$9');
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(status: RunStatus.blindSelect, endless: true),
      );
      sum = RunSummary(c.read(runProvider));
      expect(sum.headline, 'Ante 3 · Big Blind · Endless');
      expect(sum.detail, 'Choosing a blind · \$9');
      n.debugSet(c.read(runProvider).copyWith(status: RunStatus.shopping));
      expect(RunSummary(c.read(runProvider)).detail, 'In the shop · \$9');
    });
  });
}
