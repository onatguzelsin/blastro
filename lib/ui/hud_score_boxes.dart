import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';
import '../state/placement_preview.dart';
import '../state/replay_totals.dart';

/// Blue Chips x Red Mult boxes, driven live by the score replay. While a
/// piece hovers over a clearing spot they show the previewed values instead,
/// outlined in gold.
class HudScoreBoxes extends ConsumerWidget {
  const HudScoreBoxes({super.key});

  static String format(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final totals = ref.watch(replayTotalsProvider);
    final preview = ref.watch(placementPreviewProvider);
    final chips = preview?.chips ?? totals.chips;
    final mult = preview?.mult ?? totals.mult;
    final previewing = preview != null;
    return Row(
      children: [
        Expanded(
          child: _box(
            format(chips),
            t(previewing ? HudStr.previewChips : HudStr.chips),
            const Color(0xFF1976D2),
            previewing,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '×',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: _box(
            format(mult),
            t(previewing ? HudStr.previewMult : HudStr.mult),
            const Color(0xFFD32F2F),
            previewing,
          ),
        ),
      ],
    );
  }

  Widget _box(String value, String label, Color color, bool previewing) =>
      Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        // Drawn on top, so the gold outline takes no space from the number
        // and label (an inside border overflowed the box by 1px).
        foregroundDecoration: previewing
            ? BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, letterSpacing: 1.5),
            ),
          ],
        ),
      );
}
