import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:blastro/ui/how_to_play_sheet.dart';
import 'package:blastro/ui/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RunPersistence> _store({bool withSave = false}) async {
  SharedPreferences.setMockInitialValues({});
  final store = RunPersistence(await SharedPreferences.getInstance());
  if (withSave) {
    final c = ProviderContainer(
      overrides: [runPersistenceProvider.overrideWithValue(store)],
    );
    final n = c.read(runProvider.notifier)..newRun(5);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(ante: 3, blind: BlindType.big, score: 12, gold: 9),
    );
    n.saveNow();
    c.dispose();
  }
  return store;
}

Future<ProviderContainer> _pumpMenu(
  WidgetTester t,
  RunPersistence store,
) async {
  await t.binding.setSurfaceSize(const Size(400, 860));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer(
    overrides: [
      runPersistenceProvider.overrideWithValue(store),
      savedRunProvider.overrideWithValue(store.load()),
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

FilledButton _filled(WidgetTester t, String label) => t.widget<FilledButton>(
  find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
);

void main() {
  group('Main Menu', () {
    testWidgets('no save: Continue is disabled, New Run and rules available', (
      t,
    ) async {
      await _pumpMenu(t, await _store());
      expect(find.text('BLASTRO'), findsOneWidget);
      expect(find.text('No run in progress'), findsOneWidget);
      expect(_filled(t, 'Continue Run').onPressed, isNull);
      expect(find.text('New Run'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
    });

    testWidgets('with a save: Continue is enabled and shows Ante and score', (
      t,
    ) async {
      await _pumpMenu(t, await _store(withSave: true));
      expect(_filled(t, 'Continue Run').onPressed, isNotNull);
      expect(find.textContaining('Ante 3 · Big Blind'), findsOneWidget);
      expect(find.textContaining('Score 12 / 3000'), findsOneWidget);
      expect(find.textContaining('\$9'), findsOneWidget);
    });

    testWidgets('How to Play opens the rules and closes again', (t) async {
      await _pumpMenu(t, await _store());
      await t.tap(find.text('How to Play'));
      await t.pumpAndSettle();
      expect(find.text('The goal'), findsOneWidget);
      expect(find.text('Scoring: Chips x Mult'), findsOneWidget);
      expect(howToPlaySections.length, greaterThanOrEqualTo(6));
      await t.tap(find.byIcon(Icons.close));
      await t.pumpAndSettle();
      expect(find.text('The goal'), findsNothing);
    });

    testWidgets('New Run with a save asks first; Cancel keeps the run', (
      t,
    ) async {
      final store = await _store(withSave: true);
      final c = await _pumpMenu(t, store);
      await t.tap(find.text('New Run'));
      await t.pumpAndSettle();
      expect(find.text('Start a new run?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(c.read(runProvider).ante, 3, reason: 'run untouched');
    });

    testWidgets('New Run opens the game on the Blind Select hub', (t) async {
      final c = await _pumpMenu(t, await _store());
      await t.tap(find.text('New Run'));
      await t.pump();
      await _settleGame(t);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(c.read(runProvider).status, RunStatus.blindSelect);
      expect(find.text('ANTE 1'), findsOneWidget);
      expect(find.text('Play Blind'), findsOneWidget);
    });

    testWidgets('Continue resumes the saved run without resetting it', (
      t,
    ) async {
      final c = await _pumpMenu(t, await _store(withSave: true));
      await t.tap(find.text('Continue Run'));
      await t.pump();
      await _settleGame(t);
      expect(find.byType(GameScreen), findsOneWidget);
      expect([c.read(runProvider).ante, c.read(runProvider).score], [3, 12]);
      expect(find.text('Big Blind · Ante 3'), findsOneWidget);
    });

    testWidgets('the Menu button returns to the menu and Continue appears', (
      t,
    ) async {
      await _pumpMenu(t, await _store());
      await t.tap(find.text('New Run'));
      await t.pump();
      await _settleGame(t);
      await t.tap(find.text('Menu'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(_filled(t, 'Continue Run').onPressed, isNotNull);
      expect(find.textContaining('Ante 1 · Small Blind'), findsOneWidget);
    });
  });
}
