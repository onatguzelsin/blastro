import 'package:flutter/material.dart';

import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/blind_preview.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// One blind on the Blind Select screen: status, target, reward, and for the
/// current blind the Play (and, for Small/Big, Skip) buttons. The Boss card is
/// red and spells out the boss's exact rule so the player can prepare.
class BlindCard extends ConsumerWidget {
  const BlindCard({super.key, required this.preview, this.onPlay, this.onSkip});

  final BlindPreview preview;
  final VoidCallback? onPlay;
  final VoidCallback? onSkip;

  bool get _isBoss => preview.blind == BlindType.boss;

  static String statusLabel(BlindCardStatus s, AppStrings strings) =>
      strings.t(switch (s) {
        BlindCardStatus.completed => FlowStr.completed,
        BlindCardStatus.skipped => FlowStr.skipped,
        BlindCardStatus.current => FlowStr.playNow,
        BlindCardStatus.locked => FlowStr.locked,
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final current = preview.status == BlindCardStatus.current;
    final accent = _isBoss ? const Color(0xFFFF5252) : const Color(0xFF5C8DFF);
    return Opacity(
      // A locked Small/Big card is dimmed, but never the Boss: its rule has
      // to stay fully readable so the player can prepare for it.
      opacity: (preview.status == BlindCardStatus.locked && !_isBoss)
          ? 0.55
          : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isBoss ? const Color(0xFF3A1418) : const Color(0xFF1E2433),
          border: Border.all(
            color: current ? const Color(0xFFFFD54F) : accent,
            width: current ? 3 : 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isBoss)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFEB3B),
                    ),
                  ),
                Text(
                  strings.blind(preview.blind),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _badge(preview.status, strings),
              ],
            ),
            if (_isBoss && preview.boss != null) _bossRule(preview, strings),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    t(HudStr.target),
                    '${preview.target}',
                    const Color(0xFFFFD54F),
                  ),
                ),
                Expanded(
                  child: _stat(
                    t(FlowStr.reward),
                    '\$${preview.reward}',
                    const Color(0xFF69F0AE),
                  ),
                ),
              ],
            ),
            if (current) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onPlay,
                      child: Text(t(FlowStr.playBlind)),
                    ),
                  ),
                  if (preview.canSkip) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSkip,
                        child: Text(t(FlowStr.skipBlind)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bossRule(BlindPreview p, AppStrings strings) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFB71C1C),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.nameOf(p.boss!.id, p.boss!.name).toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          strings.descriptionOf(p.boss!.id, p.boss!.description),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFEB3B),
          ),
        ),
      ],
    ),
  );

  Widget _badge(BlindCardStatus s, AppStrings strings) {
    final color = switch (s) {
      BlindCardStatus.current => const Color(0xFFFFD54F),
      BlindCardStatus.completed => const Color(0xFF69F0AE),
      _ => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel(s, strings),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );
}
