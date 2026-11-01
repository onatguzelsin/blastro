import 'package:flutter/material.dart';

import '../core/roguelite/boss_blinds.dart';
import '../core/scoring/clear_archetypes.dart';

/// High-contrast warning shown during a Boss Blind round: the boss's name and
/// its exact rule. For The Eye / The Mouth it also lists the clear types
/// already used this blind, since those decide what still scores.
class BossBanner extends StatelessWidget {
  const BossBanner({
    super.key,
    required this.boss,
    this.usedArchetypes = const [],
  });

  final BossBlind boss;
  final List<ClearArchetype> usedArchetypes;

  bool get _tracksUsed => boss.oncePerArchetype || boss.firstArchetypeOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        border: Border.all(color: const Color(0xFFFFEB3B), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFEB3B),
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  boss.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  boss.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_tracksUsed && usedArchetypes.isNotEmpty)
                  Text(
                    'Used: ${usedArchetypes.map(label).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFEB3B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `parallelDouble` -> `Parallel Double`.
  static String label(ClearArchetype a) => a.name
      .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m[1]}')
      .replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase());
}
