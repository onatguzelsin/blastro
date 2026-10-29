import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/blastro_game.dart';
import 'bag_modal.dart';
import 'cash_out_sheet.dart';
import 'hud_score_boxes.dart';
import 'hud_top_bar.dart';
import 'joker_reorder_bar.dart';
import 'lifecycle_auto_save.dart';
import 'run_over_overlay.dart';
import 'shop_sheet.dart';
import 'victory_modal.dart';

/// Full-screen Flame canvas with Flutter overlays on top. Every overlay sits
/// inside a SafeArea so notches and gesture bars never clip the HUD.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  BlastroGame? _game;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final game = _game ??= BlastroGame(
      container: ProviderScope.containerOf(context),
      topInset: padding.top,
      bottomInset: padding.bottom,
    );
    return LifecycleAutoSave(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1220),
        body: GameWidget<BlastroGame>(
          game: game,
          initialActiveOverlays: const ['hud'],
          overlayBuilderMap: {
            'hud': (context, game) => SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const JokerReorderBar(),
                      const SizedBox(height: 6),
                      HudTopBar(
                        onBag: () => game.overlays.add(BlastroGame.bagOverlay),
                      ),
                      const SizedBox(height: 6),
                      const HudScoreBoxes(),
                    ],
                  ),
                ),
              ),
            ),
            BlastroGame.cashOutOverlay: (context, game) => const CashOutSheet(),
            BlastroGame.victoryOverlay: (context, game) =>
                VictoryModal(onNewRun: game.startNewRun),
            BlastroGame.shopOverlay: (context, game) => const ShopSheet(),
            BlastroGame.bagOverlay: (context, game) => BagModal(
              onClose: () => game.overlays.remove(BlastroGame.bagOverlay),
            ),
            BlastroGame.runOverOverlay: (context, game) =>
                SafeArea(child: RunOverOverlay(onNewRun: game.startNewRun)),
          },
        ),
      ),
    );
  }
}
