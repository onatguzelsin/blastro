import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_preview.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/blind_card.dart';
import 'package:blastro/ui/blind_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Blind Select cards', () {
    List<BlindPreview> cards(
      BlindType current, {
      int ante = 1,
      int seed = 1,
      Set<BlindType> skipped = const {},
    }) => BlindPreviews.forAnte(
      ante: ante,
      seed: seed,
      current: current,
      skipped: skipped,
    );

    Future<void> pumpCard(
      WidgetTester t,
      BlindPreview p, {
      VoidCallback? play,
      VoidCallback? skip,
    }) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlindCard(preview: p, onPlay: play, onSkip: skip),
            ),
          ),
        ),
      );
    }

    testWidgets('current Small card: target, reward, Play and Skip', (t) async {
      var played = 0, skipped = 0;
      await pumpCard(
        t,
        cards(BlindType.small)[0],
        play: () => played++,
        skip: () => skipped++,
      );
      expect(find.text('Small Blind'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('\$4'), findsOneWidget);
      await t.tap(find.text('Play Blind'));
      await t.tap(find.text('Skip Blind'));
      expect([played, skipped], [1, 1]);
    });

    testWidgets('current Boss card: no Skip button', (t) async {
      await pumpCard(t, cards(BlindType.boss)[2]);
      expect(find.text('Play Blind'), findsOneWidget);
      expect(find.text('Skip Blind'), findsNothing);
    });

    testWidgets('completed, skipped and locked cards have no buttons', (
      t,
    ) async {
      final c = cards(BlindType.boss, skipped: {BlindType.small});
      await pumpCard(t, c[0]);
      expect(find.text('SKIPPED'), findsOneWidget);
      expect(find.text('Play Blind'), findsNothing);
      await pumpCard(t, c[1]);
      expect(find.text('COMPLETED'), findsOneWidget);
      await pumpCard(t, cards(BlindType.small)[1]);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Play Blind'), findsNothing);
      expect(find.text('Skip Blind'), findsNothing);
    });

    testWidgets('Boss card shows the boss name and its exact rule', (t) async {
      for (final boss in BossRegistry.all.where((b) => !b.finisher)) {
        final seed = List.generate(
          3000,
          (i) => i,
        ).firstWhere((s) => BossRegistry.pick(1, s) == boss);
        await pumpCard(t, cards(BlindType.small, seed: seed)[2]);
        expect(find.text(boss.name.toUpperCase()), findsOneWidget);
        expect(find.text(boss.description), findsOneWidget);
      }
    });

    testWidgets('a locked Boss card is not dimmed, a locked Big card is', (
      t,
    ) async {
      double opacityOf(Finder f) => t
          .widget<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)))
          .opacity;
      final c = cards(BlindType.small);
      await pumpCard(t, c[2]);
      expect(c[2].status, BlindCardStatus.locked);
      expect(opacityOf(find.text('Boss Blind')), 1.0);
      await pumpCard(t, c[1]);
      expect(opacityOf(find.text('Big Blind')), 0.55);
    });

    testWidgets('Ante 8 Boss card shows Violet Vessel and 100000', (t) async {
      await pumpCard(t, cards(BlindType.small, ante: 8)[2]);
      expect(find.text('VIOLET VESSEL'), findsOneWidget);
      expect(find.text('100000'), findsOneWidget);
    });
  });

  group('Blind Select screen', () {
    Future<ProviderContainer> pumpHub(
      WidgetTester t, {
      VoidCallback? onMenu,
    }) async {
      await t.binding.setSurfaceSize(const Size(400, 860));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(runProvider.notifier).startRun(21);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: BlindSelectScreen(onMenu: onMenu ?? () {})),
        ),
      );
      return c;
    }

    testWidgets('shows all three blinds of the ante at once', (t) async {
      await pumpHub(t);
      expect(find.text('ANTE 1'), findsOneWidget);
      expect(find.text('Small Blind'), findsOneWidget);
      expect(find.text('Big Blind'), findsOneWidget);
      expect(find.text('Boss Blind'), findsOneWidget);
      expect(find.text('LOCKED'), findsNWidgets(2));
    });

    testWidgets('the Boss rule is visible before the Boss is reached', (
      t,
    ) async {
      final c = await pumpHub(t);
      final boss = BossRegistry.pick(1, c.read(runProvider).seed);
      expect(find.text(boss.name.toUpperCase()), findsOneWidget);
      expect(find.text(boss.description), findsOneWidget);
    });

    testWidgets('Play Blind starts the round', (t) async {
      final c = await pumpHub(t);
      await t.tap(find.text('Play Blind'));
      expect(c.read(runProvider).status, RunStatus.playing);
    });

    testWidgets('Skip Blind moves on to the Big Blind card', (t) async {
      final c = await pumpHub(t);
      await t.tap(find.text('Skip Blind'));
      await t.pump();
      expect(c.read(runProvider).blind, BlindType.big);
      expect(find.text('SKIPPED'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
    });

    testWidgets('Menu button calls back', (t) async {
      var called = false;
      await pumpHub(t, onMenu: () => called = true);
      await t.tap(find.text('Menu'));
      expect(called, isTrue);
    });

    testWidgets('Endless Mode is labelled', (t) async {
      final c = await pumpHub(t);
      c
          .read(runProvider.notifier)
          .debugSet(c.read(runProvider).copyWith(endless: true, ante: 9));
      await t.pump();
      expect(find.text('Endless Mode'), findsOneWidget);
      expect(find.text('ANTE 9'), findsOneWidget);
    });
  });
}
