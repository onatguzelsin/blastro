import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:blastro/core/scoring/score_preview.dart';
import 'package:blastro/ui/score_preview_line.dart';
import 'package:blastro/core/i18n/supported_language.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/state/hud_callout.dart';
import 'package:blastro/state/locale_provider.dart';
import 'package:blastro/state/quick_play_event.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _game(
  WidgetTester t, {
  bool quick = false,
  RunState Function(RunState)? setup,
}) async {
  await t.binding.setSurfaceSize(const Size(400, 860));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer(
    overrides: [deviceLanguageProvider.overrideWithValue('tr')],
  );
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier);
  quick ? n.startQuickPlay(1) : n.newRun(1);
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

void main() {
  testWidgets('the normal HUD speaks Turkish', (t) async {
    await _game(t);
    expect(find.text('Hamle'), findsOneWidget);
    expect(find.text('Atma'), findsOneWidget);
    expect(find.text('Kasa'), findsOneWidget);
    expect(find.text('Yenileme'), findsOneWidget);
    expect(find.textContaining('Hedef'), findsOneWidget);
    expect(find.text('ÇİP'), findsOneWidget);
    expect(find.text('ÇARPAN'), findsOneWidget);
    expect(find.textContaining('Küçük Blind'), findsOneWidget);
    expect(find.text('Trays'), findsNothing);
  });

  testWidgets('the Quick Play HUD and its jokers speak Turkish', (t) async {
    await _game(t, quick: true);
    expect(find.text('HIZLI OYUN'), findsOneWidget);
    expect(find.text('Hamle'), findsOneWidget);
    expect(find.text('Kombo'), findsOneWidget);
    expect(find.text('Rekor'), findsOneWidget);
    expect(find.text('Başmimar'), findsOneWidget);
    expect(find.text('Taslak'), findsOneWidget);
    expect(find.text('Köşe Taşı'), findsOneWidget);
    expect(find.text('Grand Architect'), findsNothing);
  });

  testWidgets('the Boss banner shows the Turkish name and rule', (t) async {
    await _game(
      t,
      setup: (s) => s.copyWith(blind: BlindType.boss, boss: BossRegistry.wall),
    );
    expect(find.text('DUVAR'), findsOneWidget);
    expect(find.text('Hedef, Ante tabanının 4 katı'), findsOneWidget);
  });

  testWidgets('floating callouts are Turkish: +8 HAMLE!', (t) async {
    final c = await _game(t, quick: true);
    c
        .read(hudCalloutProvider.notifier)
        .show(
          const QuickPlayEvent(trayRefund: 8, windTrays: 10, rescuedRows: 3),
        );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('+8 HAMLE!'), findsOneWidget);
    expect(find.text('İKİNCİ NEFES! +10 HAMLE'), findsOneWidget);
    expect(find.text('KURTARMA! 3 satır temizlendi'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('the live preview names the clear in Turkish', (t) async {
    await _game(t);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [deviceLanguageProvider.overrideWithValue('tr')],
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final a in [
                  ClearArchetype.single,
                  ClearArchetype.crossClear,
                ])
                  ScorePreviewLine(
                    summary: PreviewSummary(
                      title: 'x',
                      chips: 50,
                      mult: 2,
                      score: 100,
                      archetype: a,
                    ),
                  ),
                ScorePreviewLine(
                  summary: const PreviewSummary(
                    title: 'x',
                    chips: 0,
                    mult: 0,
                    score: 0,
                    blockedBy: 'The Eye',
                    blockedById: 'boss_eye',
                    archetype: ClearArchetype.single,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('TEKLİ ÇİZGİ'), findsOneWidget);
    expect(find.text('KESİŞEN ARTI!'), findsOneWidget);
    expect(find.text('TEKLİ ÇİZGİ · Göz'), findsOneWidget);
    expect(find.text('ENGELLENDİ +0'), findsOneWidget);
    expect(find.text('50 × 2 = +100'), findsNWidgets(2));
  });

  testWidgets('switching language redraws a running game at once', (t) async {
    final c = await _game(t, quick: true);
    c.read(languageProvider.notifier).select(Languages.english);
    await t.pump();
    expect(find.text('QUICK PLAY'), findsOneWidget);
    expect(find.text('Grand Architect'), findsOneWidget);
    expect(find.text('Hamle'), findsNothing);
  });
}
