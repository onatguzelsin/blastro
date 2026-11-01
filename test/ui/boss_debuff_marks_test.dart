import 'dart:ui' as ui;

import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/game/board_component.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/debuff_cross.dart';
import 'package:blastro/ui/joker_reorder_bar.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget child,
  RunState Function(RunState) setup,
) async {
  await t.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  n.debugSet(setup(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(body: SafeArea(child: child)),
      ),
    ),
  );
  await t.pump();
  return c;
}

RunState _boss(RunState s, BossBlind boss, {RunStatus? status}) => s.copyWith(
  blind: BlindType.boss,
  boss: boss,
  status: status ?? RunStatus.playing,
);

void main() {
  group('debuffed jokers get a red cross', () {
    RunState withJokers(RunState s, BossBlind boss) => _boss(s, boss).copyWith(
      jokers: [
        for (final id in ['joker_plain', 'joker_amplifier'])
          JokerRegistry.byId(id).joker,
      ],
    );

    Finder crossOn(String jokerName) => find.descendant(
      of: find.ancestor(
        of: find.text(jokerName),
        matching: find.byType(DebuffCross),
      ),
      matching: find.byType(CustomPaint),
    );

    bool active(WidgetTester t, String name) => t
        .widget<DebuffCross>(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(DebuffCross),
          ),
        )
        .active;

    testWidgets('Violet Vessel marks Amplifier (XMult) but not Plain Joker', (
      t,
    ) async {
      await _pump(
        t,
        const JokerReorderBar(),
        (s) => withJokers(s, BossRegistry.violetVessel),
      );
      expect(active(t, 'Amplifier'), isTrue);
      expect(active(t, 'Plain Joker'), isFalse);
      expect(crossOn('Amplifier'), findsWidgets);
    });

    testWidgets('no marks when there is no Boss round', (t) async {
      await _pump(
        t,
        const JokerReorderBar(),
        (s) => withJokers(
          s,
          BossRegistry.violetVessel,
        ).copyWith(status: RunStatus.shopping),
      );
      expect(active(t, 'Amplifier'), isFalse);
    });

    testWidgets('rule-only bosses mark no joker', (t) async {
      await _pump(
        t,
        const JokerReorderBar(),
        (s) => withJokers(s, BossRegistry.wall),
      );
      expect(active(t, 'Amplifier'), isFalse);
      expect(active(t, 'Plain Joker'), isFalse);
    });
  });

  group('debuffed board cells get a red cross', () {
    final layout = GameLayout.compute(Vector2(400, 800));

    /// Renders the board and returns the RGBA of the pixel at the centre of
    /// cell (0, 0) -- where the two strokes of the cross meet.
    Future<Color> centreOfFirstCell(
      WidgetTester t,
      GridCell cell,
      BossBlind? boss,
    ) async {
      final board = BoardComponent(layout, GridMatrix()..setCell(0, 0, cell))
        ..boss = boss;
      final recorder = ui.PictureRecorder();
      board.render(Canvas(recorder));
      final image = await t.runAsync(
        () => recorder.endRecording().toImage(400, 400),
      );
      final data = (await t.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final c = (layout.cell / 2).round();
      final i = (c * 400 + c) * 4;
      return Color.fromARGB(
        data.getUint8(i + 3),
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
    }

    const redCross = Color(0xFFFF1744);
    const bonus = GridCell(enhancement: CellEnhancement.bonus);

    testWidgets('The Window crosses an enhanced cell in red', (t) async {
      expect(await centreOfFirstCell(t, bonus, BossRegistry.window), redCross);
    });

    testWidgets('the same cell is not crossed without a Boss', (t) async {
      final c = await centreOfFirstCell(t, bonus, null);
      expect(c, isNot(redCross));
      // Bonus is drawn as metallic gold (no longer flat blue).
      expect(c.r, greaterThan(0.85));
      expect(c.g, inInclusiveRange(0.55, 0.95));
      expect(c.b, lessThan(0.55));
    });

    testWidgets('The Window leaves a plain cell alone', (t) async {
      final c = await centreOfFirstCell(t, GridCell.plain, BossRegistry.window);
      expect(c, isNot(redCross));
    });

    testWidgets('The Pillar crosses Steel but not other enhancements', (
      t,
    ) async {
      const steel = GridCell(enhancement: CellEnhancement.steel);
      expect(await centreOfFirstCell(t, steel, BossRegistry.pillar), redCross);
      expect(
        await centreOfFirstCell(t, bonus, BossRegistry.pillar),
        isNot(redCross),
      );
    });

    testWidgets('a rule-only boss crosses nothing', (t) async {
      const steel = GridCell(enhancement: CellEnhancement.steel);
      expect(
        await centreOfFirstCell(t, steel, BossRegistry.wall),
        isNot(redCross),
      );
    });
  });
}
