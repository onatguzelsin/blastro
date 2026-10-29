import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/ante_scaling.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';

/// Telemetry HUD under the joker bar: blind target + progress, and the
/// Trays / Discards / Rerolls / Bankroll row.
class HudTopBar extends ConsumerWidget {
  const HudTopBar({super.key, this.onBag});

  /// Opens the Block Bag modal.
  final VoidCallback? onBag;

  /// `Small Blind`, `Big Blind`, or the active Boss's own name.
  static String blindName(RunState s) => switch (s.blind) {
    BlindType.small => 'Small Blind',
    BlindType.big => 'Big Blind',
    BlindType.boss => s.boss?.name ?? 'Boss Blind',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                      '${blindName(s)} · Ante ${s.ante}${s.endless ? ' · Endless' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    'Target ${s.target}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Score ${s.score}',
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
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: StatBox(label: 'Trays', value: '${s.traysRemaining}'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatBox(
                label: 'Discards',
                value: '${s.discards}',
                color: const Color(0xFFEF5350),
                onTap: () => ref.read(runProvider.notifier).discardTray(),
              ),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: StatBox(label: 'Rerolls', value: '0'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatBox(
                label: 'Bankroll',
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

class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          border: Border.all(color: onTap != null ? color : Colors.white12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
