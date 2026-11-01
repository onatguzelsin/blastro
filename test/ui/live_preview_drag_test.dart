import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/state/placement_preview.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real touch drags through the real GameScreen.
void main() {
  const size = Size(400, 860);
  final layout = GameLayout.compute(Vector2(size.width, size.height));

  Offset toOffset(Vector2 v) => Offset(v.x, v.y);

  /// Where the finger must be so the dragged piece's centre is at [centre]
  /// (the piece is drawn 80dp above the finger).
  Offset fingerFor(Vector2 centre) =>
      toOffset(centre - GameLayout.fingerOffset);

  Future<ProviderContainer> boot(
    WidgetTester t, {
    required GridMatrix grid,
    List<String> jokers = const [],
  }) async {
    await t.binding.setSurfaceSize(size);
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(runProvider.notifier)..newRun(1);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            grid: grid,
            tray: [PolyominoCatalog.byId('dot'), null, null],
            jokers: [for (final id in jokers) JokerRegistry.byId(id).joker],
          ),
    );
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

  Future<TestGesture> grab(WidgetTester t) =>
      t.startGesture(toOffset(layout.trayCenter(0)));

  Future<void> hover(WidgetTester t, TestGesture g, Vector2 pieceCentre) async {
    final to = fingerFor(pieceCentre);
    // Several small moves, like a real finger.
    await g.moveTo(to);
    await t.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(0.5, 0));
    await t.pump(const Duration(milliseconds: 16));
  }

  GridMatrix almostRow() {
    final g = GridMatrix();
    for (var c = 0; c < 7; c++) {
      g.setCell(0, c, GridCell.plain);
    }
    return g..setCell(5, 5, GridCell.plain);
  }

  testWidgets('hovering a clearing spot shows the archetype and the numbers', (
    t,
  ) async {
    final c = await boot(t, grid: almostRow());
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(0, 7));

    final preview = c.read(placementPreviewProvider);
    expect(preview, isNotNull);
    expect(preview!.title, 'SINGLE LINE');
    expect(preview.chips, 90);
    expect(preview.score, greaterThan(0));
    expect(find.text('SINGLE LINE'), findsOneWidget);
    expect(find.text('PREVIEW CHIPS'), findsOneWidget);
    expect(find.textContaining('= +${preview.score}'), findsOneWidget);
    await g.cancel();
  });

  testWidgets('the preview matches what the drop actually scores', (t) async {
    final c = await boot(t, grid: almostRow(), jokers: ['joker_plain']);
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(0, 7));
    final promised = c.read(placementPreviewProvider)!.score;
    expect(promised, greaterThan(0));

    await g.up();
    await t.pump(const Duration(milliseconds: 50));
    expect(c.read(runProvider).lastScore!.finalScore, promised);
    expect(c.read(runProvider).score, promised);
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  });

  testWidgets('moving to an invalid spot clears the preview at once', (
    t,
  ) async {
    final c = await boot(t, grid: almostRow());
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(0, 7));
    expect(c.read(placementPreviewProvider), isNotNull);

    await hover(t, g, layout.cellCenter(0, 3)); // occupied -> illegal
    expect(c.read(placementPreviewProvider), isNull);
    expect(find.text('SINGLE LINE'), findsNothing);
    expect(find.text('Score 0'), findsOneWidget);

    await hover(t, g, layout.cellCenter(0, 7)); // and it comes back
    expect(c.read(placementPreviewProvider), isNotNull);
    await g.cancel();
  });

  testWidgets('a spot that clears nothing shows no preview', (t) async {
    final c = await boot(t, grid: almostRow());
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(3, 3));
    expect(c.read(placementPreviewProvider), isNull);
    await g.cancel();
  });

  testWidgets('releasing the piece clears the preview', (t) async {
    final c = await boot(t, grid: almostRow());
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(0, 7));
    expect(c.read(placementPreviewProvider), isNotNull);
    await g.up();
    await t.pump(const Duration(milliseconds: 50));
    expect(c.read(placementPreviewProvider), isNull);
    expect(c.read(runProvider).status, RunStatus.playing);
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  });

  testWidgets(
    'releasing on an illegal spot also clears it and places nothing',
    (t) async {
      final c = await boot(t, grid: almostRow());
      final g = await grab(t);
      await t.pump(const Duration(milliseconds: 50));
      await hover(t, g, layout.cellCenter(0, 7));
      await hover(t, g, layout.cellCenter(0, 2));
      await g.up();
      await t.pump(const Duration(milliseconds: 50));
      expect(c.read(placementPreviewProvider), isNull);
      expect(c.read(runProvider).placements, 0);
    },
  );

  testWidgets('cancelling the drag clears the preview', (t) async {
    final c = await boot(t, grid: almostRow());
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    await hover(t, g, layout.cellCenter(0, 7));
    expect(c.read(placementPreviewProvider), isNotNull);
    await g.cancel();
    await t.pump(const Duration(milliseconds: 50));
    expect(c.read(placementPreviewProvider), isNull);
  });

  testWidgets('hovering never changes the run state', (t) async {
    final c = await boot(t, grid: almostRow());
    final before = c.read(runProvider);
    final g = await grab(t);
    await t.pump(const Duration(milliseconds: 50));
    for (var col = 0; col < 8; col++) {
      await hover(t, g, layout.cellCenter(0, col));
    }
    final during = c.read(runProvider);
    expect(during.placements, before.placements);
    expect(during.score, before.score);
    expect(during.grid.toJson(), before.grid.toJson());
    await g.cancel();
  });
}
