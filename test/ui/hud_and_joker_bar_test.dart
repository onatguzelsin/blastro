import 'package:blastro/core/roguelite/joker_effects.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/state/replay_totals.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/ui/hud_score_boxes.dart';
import 'package:blastro/ui/hud_top_bar.dart';
import 'package:blastro/ui/joker_reorder_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget child, {
  List<String> jokerIds = const [],
}) async {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          jokers: [for (final id in jokerIds) JokerRegistry.byId(id).joker],
        ),
  );
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ),
      ),
    ),
  );
  return c;
}

void main() {
  testWidgets('HUD shows target, trays, discards and bankroll', (t) async {
    await _pump(t, const HudTopBar());
    expect(find.text('Small Blind · Ante 1'), findsOneWidget);
    expect(find.text('Target 300'), findsOneWidget);
    expect(find.text('Trays'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Discards'), findsOneWidget);
    expect(find.text('\$4'), findsOneWidget);
  });

  testWidgets('tapping Discards spends a charge', (t) async {
    final c = await _pump(t, const HudTopBar());
    await t.tap(find.text('Discards'));
    await t.pump();
    expect(c.read(runProvider).discards, 2);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Chips x Mult boxes follow the replay totals', (t) async {
    final c = await _pump(t, const HudScoreBoxes());
    expect(find.text('0'), findsNWidgets(2));
    c.read(replayTotalsProvider.notifier).set(90, 7.5);
    await t.pump();
    expect(find.text('90'), findsOneWidget);
    expect(find.text('7.5'), findsOneWidget);
  });

  testWidgets('joker bar renders 5 slots: 2 jokers + 3 empty', (t) async {
    await _pump(
      t,
      const JokerReorderBar(),
      jokerIds: ['joker_plain', 'joker_amplifier'],
    );
    expect(find.byType(JokerCard), findsNWidgets(2));
    expect(find.byType(EmptyJokerSlot), findsNWidgets(3));
    expect(find.text('+4 Mult'), findsOneWidget);
    expect(find.text('x1.5'), findsOneWidget);
  });

  testWidgets('long-press drag reorders jokers', (t) async {
    final c = await _pump(
      t,
      const JokerReorderBar(),
      jokerIds: ['joker_plain', 'joker_amplifier'],
    );
    final first = c.read(runProvider).jokers.first.id;
    final g = await t.startGesture(t.getCenter(find.byType(JokerCard).first));
    await t.pump(const Duration(milliseconds: 600));
    await g.moveBy(const Offset(120, 0));
    await t.pump(const Duration(milliseconds: 200));
    await g.moveBy(const Offset(80, 0));
    await t.pump(const Duration(milliseconds: 200));
    await g.up();
    await t.pumpAndSettle();
    expect(c.read(runProvider).jokers.last.id, first);
  });

  test('joker labels', () {
    expect(
      JokerCard.nameOf(JokerRegistry.byId('joker_plain').joker),
      'Plain Joker',
    );
    expect(
      JokerCard.effectOf(const Joker(id: 'x', chips: 4, xMult: 2)),
      '+4 Chips\nx2',
    );
  });
}
