import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/bag_modal.dart';
import 'package:blastro/ui/deck_select_screen.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:blastro/ui/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RunPersistence> _store() async {
  SharedPreferences.setMockInitialValues({});
  return RunPersistence(await SharedPreferences.getInstance());
}

Future<ProviderContainer> _menu(WidgetTester t, RunPersistence store) async {
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

Future<void> _swipeNext(WidgetTester t) async {
  await t.fling(find.byType(PageView), const Offset(-320, 0), 1500);
  await t.pumpAndSettle();
}

void main() {
  group('Main Menu -> deck picker -> game', () {
    testWidgets('New Run shows the picker; Back cancels everything', (t) async {
      final store = await _store();
      await _menu(t, store);
      await t.tap(find.text('New Run'));
      await t.pumpAndSettle();
      expect(find.byType(DeckSelectScreen), findsOneWidget);
      await t.tap(find.text('Back'));
      await t.pumpAndSettle();
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      expect(store.load(), isNull, reason: 'no run was started or saved');
    });

    testWidgets('picking Azure Architect starts a run with 6 trays', (t) async {
      final store = await _store();
      final c = await _menu(t, store);
      await t.tap(find.text('New Run'));
      await t.pumpAndSettle();
      await _swipeNext(t);
      await _swipeNext(t);
      await _swipeNext(t);
      expect(find.text('Azure Architect Deck'), findsOneWidget);
      await t.tap(find.text('Start Run with This Deck'));
      await t.pump();
      await _settleGame(t);
      expect(find.byType(GameScreen), findsOneWidget);
      final s = c.read(runProvider);
      expect(s.deckId, 'deck_azure_architect');
      expect(s.status, RunStatus.blindSelect);
      expect(s.traysRemaining, 6);
      expect(find.text('Play Blind'), findsOneWidget);
    });

    testWidgets('the saved deck shows on the Continue button', (t) async {
      final store = await _store();
      await _menu(t, store);
      await t.tap(find.text('New Run'));
      await t.pumpAndSettle();
      await _swipeNext(t);
      await t.tap(find.text('Start Run with This Deck'));
      await t.pump();
      await _settleGame(t);
      await t.tap(find.text('Menu'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Monolith Cube Deck'), findsOneWidget);
    });

    testWidgets('with a saved run, New Run still asks before the picker', (
      t,
    ) async {
      final store = await _store();
      final seed = ProviderContainer(
        overrides: [runPersistenceProvider.overrideWithValue(store)],
      );
      seed.read(runProvider.notifier).startRun(3, StarterDecks.chromaticFlush);
      seed.dispose();
      await _menu(t, store);
      await t.tap(find.text('New Run'));
      await t.pumpAndSettle();
      expect(find.text('Start a new run?'), findsOneWidget);
      expect(find.byType(DeckSelectScreen), findsNothing);
      await t.tap(find.text('New Run').last);
      await t.pumpAndSettle();
      expect(find.byType(DeckSelectScreen), findsOneWidget);
    });
  });

  group('in the game', () {
    testWidgets('Start New Run after a loss keeps the same deck', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 860));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(runProvider.notifier)
        ..newRun(5, StarterDecks.azureArchitect);
      n.debugSet(c.read(runProvider).copyWith(status: RunStatus.lost));
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: GameScreen()),
        ),
      );
      await _settleGame(t);
      expect(find.text('RUN OVER'), findsOneWidget);
      await t.tap(find.text('New Run'));
      await t.pump();
      await _settleGame(t);
      final s = c.read(runProvider);
      expect(s.deckId, 'deck_azure_architect');
      expect(s.status, RunStatus.blindSelect);
      expect(s.traysRemaining, 6);
    });
  });

  group('the Bag modal shows the deck\'s pool', () {
    Future<ProviderContainer> bag(WidgetTester t, StarterDeck deck) async {
      await t.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(runProvider.notifier).newRun(3, deck);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(body: BagModal(onClose: () {})),
          ),
        ),
      );
      await t.pumpAndSettle();
      return c;
    }

    int tiles(WidgetTester t) => t
        .widgetList<Text>(find.byType(Text))
        .where((w) => RegExp(r'^x\d+$').hasMatch(w.data ?? ''))
        .length;

    testWidgets('Monolith: just two shapes, 21 of 24 pieces left', (t) async {
      await bag(t, StarterDecks.monolithCube);
      expect(tiles(t), 2);
      expect(find.textContaining('21 of 24 pieces left'), findsOneWidget);
      expect(find.textContaining('Monolith Cube Deck'), findsOneWidget);
    });

    testWidgets('Standard: all 24 shapes', (t) async {
      await bag(t, StarterDecks.standard);
      expect(tiles(t), 24);
      expect(find.textContaining('21 of 24 pieces left'), findsOneWidget);
    });

    test('countsById only lists the given pool', () {
      final counts = BagModal.countsById([], StarterDecks.monolithCube.pool);
      expect(counts.keys.toSet(), {'rect_2x2', 'rect_3x3'});
      expect(BagModal.countsById([]).length, 24);
    });
  });
}
