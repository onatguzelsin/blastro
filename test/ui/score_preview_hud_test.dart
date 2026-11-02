import 'package:blastro/core/scoring/score_preview.dart';
import 'package:blastro/state/placement_preview.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/ui/hud_score_boxes.dart';
import 'package:blastro/ui/hud_top_bar.dart';
import 'package:blastro/ui/score_preview_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _single = PreviewSummary(
  title: 'SINGLE LINE',
  chips: 90,
  mult: 2,
  score: 180,
);
const _cross = PreviewSummary(
  title: 'CROSS CLEAR!',
  chips: 185,
  mult: 4.5,
  score: 832,
);
const _blocked = PreviewSummary(
  title: 'SINGLE LINE',
  chips: 0,
  mult: 0,
  score: 0,
  blockedBy: 'The Eye',
);

Future<ProviderContainer> _pump(WidgetTester t, Widget child) async {
  await t.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(1);
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
  group('ScorePreviewLine', () {
    Future<void> show(WidgetTester t, PreviewSummary s) => t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ScorePreviewLine(summary: s)),
        ),
      ),
    );

    testWidgets('shows the clear type and Chips × Mult = +Score', (t) async {
      await show(t, _single);
      expect(find.text('SINGLE LINE'), findsOneWidget);
      expect(find.text('90 × 2 = +180'), findsOneWidget);
    });

    testWidgets('keeps one decimal for fractional mult', (t) async {
      await show(t, _cross);
      expect(find.text('CROSS CLEAR!'), findsOneWidget);
      expect(find.text('185 × 4.5 = +832'), findsOneWidget);
    });

    testWidgets('a boss-blanked clear says who and shows BLOCKED +0 in red', (
      t,
    ) async {
      await show(t, _blocked);
      expect(find.text('SINGLE LINE · The Eye'), findsOneWidget);
      final text = t.widget<Text>(find.text('BLOCKED +0'));
      expect(text.style!.color, const Color(0xFFFF5252));
      expect(find.textContaining('×'), findsNothing);
    });
  });

  group('HudTopBar score row', () {
    testWidgets('shows the normal Score row until a preview appears', (
      t,
    ) async {
      final c = await _pump(t, const HudTopBar());
      expect(find.text('Score 0'), findsOneWidget);
      expect(find.byType(ScorePreviewLine), findsNothing);

      c.read(placementPreviewProvider.notifier).show(_single);
      await t.pump();
      expect(find.byType(ScorePreviewLine), findsOneWidget);
      expect(find.text('SINGLE LINE'), findsOneWidget);
      expect(find.text('90 × 2 = +180'), findsOneWidget);
      expect(find.text('Score 0'), findsNothing);
    });

    testWidgets('clears immediately and the Score row returns', (t) async {
      final c = await _pump(t, const HudTopBar());
      final notifier = c.read(placementPreviewProvider.notifier);
      notifier.show(_cross);
      await t.pump();
      expect(find.text('CROSS CLEAR!'), findsOneWidget);
      notifier.clear();
      await t.pump();
      expect(find.text('CROSS CLEAR!'), findsNothing);
      expect(find.text('Score 0'), findsOneWidget);
    });

    testWidgets('swapping the row never changes the HUD height', (t) async {
      final c = await _pump(t, const HudTopBar());
      final before = t.getSize(find.byType(HudTopBar));
      c.read(placementPreviewProvider.notifier).show(_single);
      await t.pump();
      expect(t.getSize(find.byType(HudTopBar)), before);
    });

    testWidgets('updates live as the hovered spot changes', (t) async {
      final c = await _pump(t, const HudTopBar());
      final notifier = c.read(placementPreviewProvider.notifier);
      notifier.show(_single);
      await t.pump();
      expect(find.text('SINGLE LINE'), findsOneWidget);
      notifier.show(_cross);
      await t.pump();
      expect(find.text('SINGLE LINE'), findsNothing);
      expect(find.text('CROSS CLEAR!'), findsOneWidget);
    });
  });

  group('Chips × Mult boxes', () {
    testWidgets('show the previewed numbers with a PREVIEW label', (t) async {
      final c = await _pump(t, const HudScoreBoxes());
      expect(find.text('CHIPS'), findsOneWidget);
      c.read(placementPreviewProvider.notifier).show(_cross);
      await t.pump();
      expect(find.text('185'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('PREVIEW CHIPS'), findsOneWidget);
      expect(find.text('PREVIEW MULT'), findsOneWidget);
      expect(find.text('CHIPS'), findsNothing);
    });

    testWidgets('go back to the real totals when the preview clears', (
      t,
    ) async {
      final c = await _pump(t, const HudScoreBoxes());
      final notifier = c.read(placementPreviewProvider.notifier);
      notifier.show(_single);
      await t.pump();
      notifier.clear();
      await t.pump();
      expect(find.text('CHIPS'), findsOneWidget);
      expect(find.text('MULT'), findsOneWidget);
      expect(find.text('PREVIEW CHIPS'), findsNothing);
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('the preview boxes have a gold outline', (t) async {
      final c = await _pump(t, const HudScoreBoxes());
      c.read(placementPreviewProvider.notifier).show(_single);
      await t.pump();
      final boxes = t
          .widgetList<Container>(find.byType(Container))
          .where((b) => b.foregroundDecoration != null);
      expect(boxes.length, 2);
    });
  });
}
