import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';
import '../state/placement_preview.dart';
import '../state/quick_play_records.dart';
import '../state/run_notifier.dart';
import 'floating_callout.dart';
import 'score_preview_line.dart';
import 'stat_box.dart';

/// The Quick Play HUD: no blind, target or bankroll, just your score, trays,
/// discards, combo and best. The floating "+N TRAYS!" pops over it.
class QuickPlayHud extends ConsumerWidget {
  const QuickPlayHud({super.key, this.onBag, this.onMenu});

  final VoidCallback? onBag;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(runProvider);
    final best = ref.watch(quickPlayBestProvider);
    final preview = ref.watch(placementPreviewProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2433),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      Expanded(
                        child: Text(
                          t(HudStr.quickPlayTag),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFFF59E0B),
                          ),
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
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (preview != null)
                    ScorePreviewLine(summary: preview)
                  else
                    SizedBox(
                      height: ScorePreviewLine.height,
                      child: Row(
                        children: [
                          Text(
                            '${t(HudStr.score)} ',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${s.score}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
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
                    color: const Color(0xFF69F0AE),
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
                  child: StatBox(
                    label: t(HudStr.combo),
                    value: 'x${s.combo.streak}',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: StatBox(
                    label: t(HudStr.best),
                    value: '$best',
                    color: const Color(0xFFFFD54F),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Positioned.fill(child: Center(child: FloatingCallout())),
      ],
    );
  }
}
