import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/state/joker_pulse.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/joker_reorder_bar.dart';
import 'package:blastro/ui/victory_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget child, {
  RunState Function(RunState)? setup,
}) async {
  await t.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  if (setup != null) n.debugSet(setup(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

double _scaleOf(WidgetTester t, int slot) => t
    .widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(JokerBounce).at(slot),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

void main() {
  RunState victory(RunState s) => s.copyWith(
    status: RunStatus.victory,
    ante: 8,
    score: 123456,
    gold: 55,
    jokers: [JokerRegistry.byId('joker_plain').joker],
  );

  testWidgets('Victory modal shows the run summary', (t) async {
    await _pump(t, VictoryModal(onNewRun: () {}), setup: victory);
    expect(find.text('Victory!'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('\$55'), findsOneWidget);
    expect(find.textContaining('Antes 9 to 39'), findsOneWidget);
  });

  testWidgets('Continue to Endless Mode keeps the run and heads to cash out', (
    t,
  ) async {
    final c = await _pump(t, VictoryModal(onNewRun: () {}), setup: victory);
    await t.tap(find.text('Continue to Endless Mode'));
    await t.pump();
    final s = c.read(runProvider);
    expect([s.status, s.endless], [RunStatus.blindCleared, true]);
    expect(s.jokers.single.id, 'joker_plain');
    expect(s.gold, 55);
  });

  testWidgets('Start New Run calls back', (t) async {
    var started = false;
    await _pump(
      t,
      VictoryModal(onNewRun: () => started = true),
      setup: victory,
    );
    await t.tap(find.text('Start New Run'));
    expect(started, isTrue);
  });

  testWidgets('a joker card bounces only when its own slot pulses', (t) async {
    final c = await _pump(
      t,
      const JokerReorderBar(),
      setup: (s) => s.copyWith(
        jokers: [
          JokerRegistry.byId('joker_plain').joker,
          JokerRegistry.byId('joker_amplifier').joker,
        ],
      ),
    );
    expect(_scaleOf(t, 0), 1.0);
    c.read(jokerPulseProvider.notifier).pulse(0);
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(_scaleOf(t, 0), greaterThan(1.05));
    expect(_scaleOf(t, 1), 1.0);
    await t.pump(const Duration(milliseconds: 400));
    expect(_scaleOf(t, 0), 1.0);
  });

  testWidgets('the same slot can pulse twice in a row', (t) async {
    final c = await _pump(
      t,
      const JokerReorderBar(),
      setup: (s) =>
          s.copyWith(jokers: [JokerRegistry.byId('joker_plain').joker]),
    );
    final pulse = c.read(jokerPulseProvider.notifier);
    pulse.pulse(0);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(_scaleOf(t, 0), 1.0);
    pulse.pulse(0);
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(_scaleOf(t, 0), greaterThan(1.05));
  });
}
