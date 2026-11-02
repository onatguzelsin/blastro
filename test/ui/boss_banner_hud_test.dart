import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/boss_banner.dart';
import 'package:blastro/ui/hud_top_bar.dart';
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
  group('BossBanner', () {
    testWidgets('shows the boss name and its exact rule', (t) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: BossBanner(boss: BossRegistry.wall)),
          ),
        ),
      );
      expect(find.text('THE WALL'), findsOneWidget);
      expect(find.text(BossRegistry.wall.description), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('is high contrast: red background, white text', (t) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: BossBanner(boss: BossRegistry.flint)),
          ),
        ),
      );
      final box = t.widget<Container>(find.byType(Container).first);
      expect((box.decoration! as BoxDecoration).color, const Color(0xFFB71C1C));
      final name = t.widget<Text>(find.text('THE FLINT'));
      expect(name.style!.color, Colors.white);
    });

    testWidgets('The Eye / The Mouth list the clear types already used', (
      t,
    ) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BossBanner(
                boss: BossRegistry.eye,
                usedArchetypes: const [
                  ClearArchetype.single,
                  ClearArchetype.parallelDouble,
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Used: Single, Parallel Double'), findsOneWidget);
    });

    testWidgets('other bosses never show a "Used" line', (t) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BossBanner(
                boss: BossRegistry.wall,
                usedArchetypes: const [ClearArchetype.single],
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Used:'), findsNothing);
    });

    test('archetype labels read naturally', () {
      expect(BossBanner.label(ClearArchetype.zone3x3), 'Zone3x3');
      expect(BossBanner.label(ClearArchetype.cleanSweep), 'Clean Sweep');
    });
  });

  group('HUD banner', () {
    testWidgets('shows in an active Boss round with name and rule', (t) async {
      await _pump(t, const HudTopBar(), (s) => _boss(s, BossRegistry.water));
      expect(find.byType(BossBanner), findsOneWidget);
      expect(find.text('THE WATER'), findsOneWidget);
      expect(find.text(BossRegistry.water.description), findsOneWidget);
    });

    testWidgets('hidden on Small and Big blinds', (t) async {
      for (final blind in [BlindType.small, BlindType.big]) {
        await _pump(t, const HudTopBar(), (s) => s.copyWith(blind: blind));
        expect(find.byType(BossBanner), findsNothing, reason: blind.name);
      }
    });

    testWidgets('hidden outside the Boss round (hub, shop)', (t) async {
      for (final status in [RunStatus.blindSelect, RunStatus.shopping]) {
        await _pump(
          t,
          const HudTopBar(),
          (s) => _boss(s, BossRegistry.wall, status: status),
        );
        expect(find.byType(BossBanner), findsNothing, reason: status.name);
      }
    });

    testWidgets('The Eye banner follows the clear types used this blind', (
      t,
    ) async {
      await _pump(
        t,
        const HudTopBar(),
        (s) => _boss(
          s,
          BossRegistry.eye,
        ).copyWith(archetypesThisBlind: [ClearArchetype.quad]),
      );
      expect(find.text('Used: Quad'), findsOneWidget);
    });

    testWidgets('Menu button is wired', (t) async {
      var tapped = false;
      await _pump(t, HudTopBar(onMenu: () => tapped = true), (s) => s);
      await t.tap(find.byIcon(Icons.menu));
      expect(tapped, isTrue);
    });
  });
}
