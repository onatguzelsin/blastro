import 'package:flutter/material.dart';

import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/blind_preview.dart';

/// One blind on the Blind Select screen: status, target, reward, and for the
/// current blind the Play (and, for Small/Big, Skip) buttons. The Boss card is
/// red and spells out the boss's exact rule so the player can prepare.
class BlindCard extends StatelessWidget {
  const BlindCard({super.key, required this.preview, this.onPlay, this.onSkip});

  final BlindPreview preview;
  final VoidCallback? onPlay;
  final VoidCallback? onSkip;

  bool get _isBoss => preview.blind == BlindType.boss;

  static String statusLabel(BlindCardStatus s) => switch (s) {
    BlindCardStatus.completed => 'COMPLETED',
    BlindCardStatus.skipped => 'SKIPPED',
    BlindCardStatus.current => 'PLAY NOW',
    BlindCardStatus.locked => 'LOCKED',
  };

  @override
  Widget build(BuildContext context) {
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
                  preview.blind.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _badge(preview.status),
              ],
            ),
            if (_isBoss && preview.boss != null) _bossRule(preview),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    'Target',
                    '${preview.target}',
                    const Color(0xFFFFD54F),
                  ),
                ),
                Expanded(
                  child: _stat(
                    'Reward',
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
                      child: const Text('Play Blind'),
                    ),
                  ),
                  if (preview.canSkip) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSkip,
                        child: const Text('Skip Blind'),
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

  Widget _bossRule(BlindPreview p) => Container(
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
          p.boss!.name.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          p.boss!.description,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFEB3B),
          ),
        ),
      ],
    ),
  );

  Widget _badge(BlindCardStatus s) {
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
        statusLabel(s),
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
