import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../core/roguelite/ante_scaling.dart';
import '../state/locale_provider.dart';
import '../state/placement_preview.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';
import 'boss_banner.dart';
import 'quick_play_hud.dart';
import 'score_preview_line.dart';
import 'stat_box.dart';

export 'stat_box.dart';

/// Telemetry HUD under the joker bar: blind target + progress, and the
/// Trays / Discards / Rerolls / Bankroll row.
class HudTopBar extends ConsumerWidget {
  const HudTopBar({super.key, this.onBag, this.onMenu});

  /// Opens the Block Bag modal.
  final VoidCallback? onBag;

  /// Returns to the main menu (the run is auto-saved).
  final VoidCallback? onMenu;

  /// `Small Blind`, `Big Blind`, or the active Boss's own name.
  static String blindName(RunState s, AppStrings strings) {
    final boss = s.boss;
    if (s.blind == BlindType.boss && boss != null) {
      return strings.nameOf(boss.id, boss.name);
    }
    return strings.blind(s.blind);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final s = ref.watch(runProvider);
    // Quick Play has no blinds or targets: it has its own HUD.
    if (s.mode.isQuickPlay) return QuickPlayHud(onBag: onBag, onMenu: onMenu);
    final preview = ref.watch(placementPreviewProvider);
    final boss = s.status == RunStatus.playing && s.blind == BlindType.boss
        ? s.boss
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (boss != null) ...[
          BossBanner(boss: boss, usedArchetypes: s.archetypesThisBlind),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${t(HudStr.anteLine, {'blind': blindName(s, strings), 'n': s.ante})}'
                      '${s.endless ? ' · ${t(HudStr.endless)}' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (onMenu != null)
                    GestureDetector(
                      onTap: onMenu,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.menu, size: 20),
                      ),
                    ),
                  if (onBag != null)
                    GestureDetector(
                      onTap: onBag,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.inventory_2_outlined, size: 20),
                      ),
                    ),
                  Text(
                    '${t(HudStr.target)} ${s.target}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // While a piece hovers over a clearing spot, this row shows
              // what dropping it there would score.
              if (preview != null)
                ScorePreviewLine(summary: preview)
              else
                SizedBox(
                  height: ScorePreviewLine.height,
                  child: Row(
                    children: [
                      Text(
                        '${t(HudStr.score)} ${s.score}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (s.score / s.target).clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: StatBox(
                label: t(HudStr.trays),
                value: '${s.traysRemaining}',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatBox(
                label: t(HudStr.discards),
                value: '${s.discards}',
                color: const Color(0xFFEF5350),
                onTap: () => ref.read(runProvider.notifier).discardTray(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatBox(label: t(HudStr.rerolls), value: '0'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatBox(
                label: t(HudStr.bankroll),
                value: '\$${s.gold}',
                color: const Color(0xFFFFD54F),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
