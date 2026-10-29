import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/state/joker_pulse.dart';
import 'package:blastro/state/replay_totals.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _boot(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(400, 860));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(1);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  return c;
}

void main() {
  testWidgets('GameScreen boots with the HUD over the Flame board', (t) async {
    await _boot(t);
    expect(find.text('Small Blind · Ante 1'), findsOneWidget);
    expect(find.text('Target 300'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('status drives the sheets: cash out, shop, back to play', (
    t,
  ) async {
    final c = await _boot(t);
    final n = c.read(runProvider.notifier);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            status: RunStatus.blindCleared,
            gold: 10,
            traysRemaining: 3,
          ),
    );
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Blind Defeated!'), findsOneWidget);

    n.collectCashOut();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Blind Defeated!'), findsNothing);
    expect(find.text('Shop'), findsOneWidget);

    n.leaveShop();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Shop'), findsNothing);
    expect(find.text('Big Blind · Ante 1'), findsOneWidget);
  });

  testWidgets('Bag button opens the Block Bag modal', (t) async {
    await _boot(t);
    await t.tap(find.byIcon(Icons.inventory_2_outlined));
    // First pump starts the slide-up ticker, the second finishes it.
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Block Bag'), findsOneWidget);
    await t.tap(find.byIcon(Icons.close));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Block Bag'), findsNothing);
  });

  testWidgets('a lost run shows the Run Over overlay', (t) async {
    final c = await _boot(t);
    c
        .read(runProvider.notifier)
        .debugSet(c.read(runProvider).copyWith(status: RunStatus.lost));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('RUN OVER'), findsOneWidget);
  });

  testWidgets('victory sheet appears, then Endless leads to cash out', (
    t,
  ) async {
    final c = await _boot(t);
    c
        .read(runProvider.notifier)
        .debugSet(
          c.read(runProvider).copyWith(status: RunStatus.victory, ante: 8),
        );
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Victory!'), findsOneWidget);
    await t.tap(find.text('Continue to Endless Mode'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Victory!'), findsNothing);
    expect(find.text('Blind Defeated!'), findsOneWidget);
  });

  testWidgets('a double clear plays the full juiced replay and settles', (
    t,
  ) async {
    final c = await _boot(t);
    final n = c.read(runProvider.notifier);
    final base = c.read(runProvider);
    n.debugSet(
      base.copyWith(
        grid: GridMatrix.fromAscii(['XXXXXXX.', 'XXXXXXX.'])
          ..setCell(5, 5, GridCell.plain),
        tray: [PolyominoCatalog.byId('bar2_v'), null, null],
        jokers: [JokerRegistry.byId('joker_plain').joker],
      ),
    );
    expect(n.placePiece(0, 0, 7), isTrue);
    final lines = c.read(runProvider).lastScore!.clears.lineCount;
    expect(lines, 2, reason: 'a multi-line clear triggers the camera shake');
    // Cell bounces, popups, haptics and the shake all run inside the replay.
    for (var i = 0; i < 80; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(c.read(runProvider).score, greaterThan(0));
    expect(c.read(replayTotalsProvider).chips, greaterThan(0));
    expect(
      c.read(jokerPulseProvider).tick,
      greaterThan(0),
      reason: 'the joker card was pulsed',
    );
    expect(t.takeException(), isNull);
  });
}
