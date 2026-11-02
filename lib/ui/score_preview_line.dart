import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';
import '../core/scoring/score_preview.dart';

/// The live "if you drop it here" line: the clear type, then
/// `Chips × Mult = +Score`. A clear that a boss blanks says so in red.
class ScorePreviewLine extends ConsumerWidget {
  const ScorePreviewLine({super.key, required this.summary});

  final PreviewSummary summary;

  /// Row height; the normal Score row uses the same so the HUD never jumps.
  static const double height = 20;

  static String formatNumber(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final archetype = summary.archetype;
    final title = archetype == null
        ? summary.title
        : strings.archetype(archetype);
    final blockedId = summary.blockedById;
    final blocked = blockedId == null
        ? summary.blockedBy
        : strings.nameOf(blockedId, summary.blockedBy ?? blockedId);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: Text(
              blocked == null ? title : '$title · $blocked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: blocked == null
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFFFF5252),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            blocked == null
                ? '${formatNumber(summary.chips)} × '
                      '${formatNumber(summary.mult)} = +${summary.score}'
                : '${strings.t(HudStr.blocked)} +0',
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: blocked == null ? Colors.white : const Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }
}
