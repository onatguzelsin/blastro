import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/state/hud_callout.dart';
import 'package:blastro/state/quick_play_event.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/floating_callout.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:blastro/ui/joker_card.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(400, 860);

final _layout = GameLayout.compute(
  Vector2(_size.width, _size.height),
  traySlots: 4,
);

Offset _at(Vector2 v) => Offset(v.x, v.y);

Future<ProviderContainer> _boot(
  WidgetTester t, {
  RunState Function(RunState)? setup,
}) async {
  await t.binding.setSurfaceSize(_size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..startQuickPlay(1);
  if (setup != null) n.debugSet(setup(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  return c;
}

/// Row 0 filled except column 7, plus a spare cell.
GridMatrix _almostRow() =>
    GridMatrix.fromAscii(['XXXXXXX.'])..setCell(7, 0, GridCell.plain);

void main() {
  group('the Quick Play HUD', () {
    testWidgets('shows score, trays, discards, combo and best', (t) async {
      await _boot(t);
      expect(find.text('QUICK PLAY'), findsOneWidget);
      expect(find.text('Score '), findsOneWidget);
      expect(find.text('Trays'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Discards'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Combo'), findsOneWidget);
      expect(find.text('x0'), findsOneWidget);
      expect(find.text('Best'), findsOneWidget);
    });

    testWidgets('has no blind, target or bankroll', (t) async {
      await _boot(t);
      expect(find.textContaining('Target'), findsNothing);
      expect(find.textContaining('Blind'), findsNothing);
      expect(find.textContaining('Ante'), findsNothing);
      expect(find.text('Bankroll'), findsNothing);
      expect(find.text('Rerolls'), findsNothing);
    });

    testWidgets('all five loadout jokers are on the bar', (t) async {
      await _boot(t);
      expect(find.byType(JokerCard), findsNWidgets(5));
      for (final name in [
        'Blueprint',
        'Grand Architect',
        'Cornerstone',
        'Heavyweight',
        'Streak Saver',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('the Discards box spends a discard', (t) async {
      final c = await _boot(t);
      await t.tap(find.text('Discards'));
      await t.pump();
      expect(c.read(runProvider).discards, 5);
    });

    testWidgets('trays, discards and combo follow the run', (t) async {
      final c = await _boot(t);
      c
          .read(runProvider.notifier)
          .debugSet(
            c.read(runProvider).copyWith(traysRemaining: 87, discards: 2),
          );
      await t.pump();
      expect(find.text('87'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('the floating +N TRAYS! callout', () {
    testWidgets('appears when a real drag clears a line, and is +8', (t) async {
      final c = await _boot(
        t,
        setup: (s) => s.copyWith(
          grid: _almostRow(),
          tray: [for (var i = 0; i < 4; i++) PolyominoCatalog.byId('dot')],
        ),
      );
      final g = await t.startGesture(_at(_layout.trayCenter(0)));
      await t.pump(const Duration(milliseconds: 50));
      await g.moveTo(_at(_layout.cellCenter(0, 7) - GameLayout.fingerOffset));
      await t.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(0.5, 0));
      await t.pump(const Duration(milliseconds: 16));
      await g.up();

      var seen = false;
      for (var i = 0; i < 80; i++) {
        await t.pump(const Duration(milliseconds: 50));
        if (find.text('+8 TRAYS!').evaluate().isNotEmpty) seen = true;
      }
      expect(seen, isTrue, reason: 'the callout popped on the HUD');
      expect(c.read(runProvider).traysRemaining, 18);
      expect(find.text('18'), findsOneWidget, reason: 'and the Trays box');
      expect(
        find.text('+8 TRAYS!'),
        findsNothing,
        reason: 'then it faded away',
      );
    });

    testWidgets('a 4th-slot piece can be dragged too', (t) async {
      final c = await _boot(
        t,
        setup: (s) => s.copyWith(
          grid: GridMatrix(),
          tray: [for (var i = 0; i < 4; i++) PolyominoCatalog.byId('dot')],
        ),
      );
      final g = await t.startGesture(_at(_layout.trayCenter(3)));
      await t.pump(const Duration(milliseconds: 50));
      await g.moveTo(_at(_layout.cellCenter(4, 4) - GameLayout.fingerOffset));
      await t.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(0.5, 0));
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      expect(c.read(runProvider).tray[3], isNull);
      expect(c.read(runProvider).grid.isOccupied(4, 4), isTrue);
    });

    testWidgets('Second Wind and Rescue texts show and then fade', (t) async {
      final c = await _boot(t);
      c
          .read(hudCalloutProvider.notifier)
          .show(const QuickPlayEvent(windTrays: 10, rescuedRows: 3));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('SECOND WIND! +10 TRAYS'), findsOneWidget);
      expect(find.text('RESCUE! 3 rows cleared'), findsOneWidget);
      await t.pump(FloatingCallout.duration);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('SECOND WIND! +10 TRAYS'), findsNothing);
    });

    testWidgets('an empty event shows nothing', (t) async {
      final c = await _boot(t);
      c.read(hudCalloutProvider.notifier).show(QuickPlayEvent.none);
      await t.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('TRAYS'), findsNothing);
      expect(c.read(hudCalloutProvider).tick, 0);
    });

    testWidgets('the same text can pop twice in a row', (t) async {
      final c = await _boot(t);
      final n = c.read(hudCalloutProvider.notifier);
      n.show(const QuickPlayEvent(trayRefund: 8));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('+8 TRAYS!'), findsOneWidget);
      await t.pump(FloatingCallout.duration);
      n.show(const QuickPlayEvent(trayRefund: 8));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('+8 TRAYS!'), findsOneWidget);
      expect(c.read(hudCalloutProvider).tick, 2);
    });
  });

  testWidgets('there is never a Run Over screen in Quick Play', (t) async {
    final c = await _boot(t);
    for (var i = 0; i < 5; i++) {
      c
          .read(runProvider.notifier)
          .debugSet(
            c
                .read(runProvider)
                .copyWith(
                  traysRemaining: 1,
                  tray: [PolyominoCatalog.byId('dot'), null, null, null],
                  grid: GridMatrix(),
                ),
          );
      c.read(runProvider.notifier).placePiece(0, i, i);
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('RUN OVER'), findsNothing);
    expect(c.read(runProvider).status, RunStatus.playing);
  });
}
