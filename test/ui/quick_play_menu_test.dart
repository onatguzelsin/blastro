import 'dart:convert';

import 'package:blastro/core/roguelite/run_mode.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/deck_select_screen.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:blastro/ui/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Env {
  _Env(this.prefs, this.store);

  final SharedPreferences prefs;
  final RunPersistence store;
}

Future<_Env> _env({bool normalRun = false, int best = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = RunPersistence(prefs);
  if (best > 0) await store.saveBestQuickPlayScore(best);
  if (normalRun) {
    final c = ProviderContainer(
      overrides: [runPersistenceProvider.overrideWithValue(store)],
    );
    c.read(runProvider.notifier).startRun(3, StarterDecks.chromaticFlush);
    c.dispose();
  }
  return _Env(prefs, store);
}

Future<ProviderContainer> _menu(WidgetTester t, _Env env) async {
  await t.binding.setSurfaceSize(const Size(400, 860));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer(
    overrides: [
      runPersistenceProvider.overrideWithValue(env.store),
      savedRunProvider.overrideWithValue(env.store.load()),
    ],
  );
  addTearDown(c.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: MainMenuScreen()),
    ),
  );
  await t.pump();
  return c;
}

Future<void> _settleGame(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _backToMenu(WidgetTester t) async {
  await t.tap(find.byIcon(Icons.menu));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  group('the Quick Play button', () {
    testWidgets('is the first and most prominent thing on the menu', (t) async {
      await _menu(t, await _env());
      expect(find.text('QUICK PLAY'), findsOneWidget);
      expect(find.text('Instant endless arcade run'), findsOneWidget);
      final quickY = t.getTopLeft(find.text('QUICK PLAY')).dy;
      expect(quickY, lessThan(t.getTopLeft(find.text('New Run')).dy));
      expect(quickY, lessThan(t.getTopLeft(find.text('Continue Run')).dy));
    });

    testWidgets('shows your best score', (t) async {
      await _menu(t, await _env(best: 4321));
      expect(find.text('BEST'), findsOneWidget);
      expect(find.text('4321'), findsOneWidget);
    });

    testWidgets('no best yet: no BEST badge', (t) async {
      await _menu(t, await _env());
      expect(find.text('BEST'), findsNothing);
    });

    testWidgets('one tap: straight onto the board, no menus in between', (
      t,
    ) async {
      final c = await _menu(t, await _env());
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(DeckSelectScreen), findsNothing);
      expect(find.text('Play Blind'), findsNothing, reason: 'no Blind Select');
      expect(find.byType(AlertDialog), findsNothing);
      final s = c.read(runProvider);
      expect(s.mode, RunMode.quickPlay);
      expect(s.status, RunStatus.playing);
      expect(s.tray.length, 4);
    });
  });

  group('it never overwrites your regular run', () {
    testWidgets(
      'no confirmation, and the normal save is byte-for-byte intact',
      (t) async {
        final env = await _env(normalRun: true);
        final before = env.prefs.getString(RunPersistence.key);
        expect(before, isNotNull);
        await _menu(t, env);
        await t.tap(find.text('QUICK PLAY'));
        await t.pump();
        await _settleGame(t);
        expect(find.text('Start a new run?'), findsNothing);
        expect(find.byType(GameScreen), findsOneWidget);
        expect(env.prefs.getString(RunPersistence.key), before);
        expect(env.prefs.getString(RunPersistence.quickPlayKey), isNotNull);
      },
    );

    testWidgets('Continue Run still resumes the regular run afterwards', (
      t,
    ) async {
      final env = await _env(normalRun: true);
      final c = await _menu(t, env);
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      await _backToMenu(t);
      expect(find.byType(MainMenuScreen), findsOneWidget);
      // The Continue button still describes the regular run.
      expect(find.textContaining('Ante 1 · Small Blind'), findsOneWidget);
      expect(find.textContaining('Chromatic Flush Deck'), findsOneWidget);

      await t.tap(find.text('Continue Run'));
      await t.pump();
      await _settleGame(t);
      final s = c.read(runProvider);
      expect(s.mode, RunMode.normal);
      expect(s.deckId, 'deck_chromatic_flush');
      expect(s.status, RunStatus.blindSelect);
      expect(find.text('Play Blind'), findsOneWidget);
    });

    testWidgets('and a regular run played in between does not end Quick Play', (
      t,
    ) async {
      final env = await _env(normalRun: true);
      await _menu(t, env);
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      await _backToMenu(t);
      final quick = env.prefs.getString(RunPersistence.quickPlayKey);
      await t.tap(find.text('Continue Run'));
      await t.pump();
      await _settleGame(t);
      expect(env.prefs.getString(RunPersistence.quickPlayKey), quick);
    });
  });

  group('resuming and restarting Quick Play', () {
    testWidgets('your run is saved and the button says where you are', (
      t,
    ) async {
      final env = await _env();
      final c = await _menu(t, env);
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      c.read(runProvider.notifier)
        ..debugSet(c.read(runProvider).copyWith(score: 1234, traysRemaining: 7))
        ..saveNow();
      await _backToMenu(t);
      expect(find.text('Resume · Score 1234 · Trays 7'), findsOneWidget);
      expect(find.text('Restart Quick Play'), findsOneWidget);
    });

    testWidgets('tapping it again resumes exactly that run', (t) async {
      final env = await _env();
      final c = await _menu(t, env);
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      c.read(runProvider.notifier)
        ..debugSet(c.read(runProvider).copyWith(score: 555, traysRemaining: 33))
        ..saveNow();
      await _backToMenu(t);
      await t.tap(find.textContaining('Resume'));
      await t.pump();
      await _settleGame(t);
      expect(c.read(runProvider).score, 555);
      expect(c.read(runProvider).traysRemaining, 33);
    });

    testWidgets('Restart asks first, then starts fresh with 10 trays', (
      t,
    ) async {
      final env = await _env();
      final c = await _menu(t, env);
      await t.tap(find.text('QUICK PLAY'));
      await t.pump();
      await _settleGame(t);
      c.read(runProvider.notifier)
        ..debugSet(c.read(runProvider).copyWith(score: 555, traysRemaining: 33))
        ..saveNow();
      await _backToMenu(t);
      await t.tap(find.text('Restart Quick Play'));
      await t.pumpAndSettle();
      expect(find.text('Restart Quick Play?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).score, 555, reason: 'cancel keeps the run');
      await t.tap(find.text('Restart Quick Play'));
      await t.pumpAndSettle();
      await t.tap(find.text('Restart'));
      await t.pump();
      await _settleGame(t);
      expect(c.read(runProvider).score, 0);
      expect(c.read(runProvider).traysRemaining, 10);
      final saved = jsonDecode(
        env.prefs.getString(RunPersistence.quickPlayKey)!,
      );
      expect(saved['trays'], 10);
    });

    testWidgets('no saved Quick Play: no Restart link', (t) async {
      await _menu(t, await _env());
      expect(find.text('Restart Quick Play'), findsNothing);
    });
  });
}
