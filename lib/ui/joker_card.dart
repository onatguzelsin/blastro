import 'package:flutter/material.dart';

import '../core/roguelite/joker_effects.dart';
import '../core/roguelite/joker_registry.dart';
import 'debuff_cross.dart';
import 'rarity_badge.dart';
import 'rarity_frame.dart';
import 'rarity_style.dart';

/// A joker in the 5-slot bar, in its rarity's colors: tinted background,
/// glowing border and a rarity pill. A debuffed joker (by the active Boss)
/// is dimmed with a red cross.
class JokerCard extends StatelessWidget {
  const JokerCard({super.key, required this.joker, this.debuffed = false});

  final Joker joker;

  /// The active Boss switches this joker off.
  final bool debuffed;

  static String nameOf(Joker j) =>
      JokerRegistry.maybeById(j.id)?.name ??
      j.id.replaceFirst('joker_', '').replaceAll('_', ' ');

  static String effectOf(Joker j) {
    final short = JokerRegistry.maybeById(j.id)?.short;
    if (short != null) return short;
    final parts = [
      if (j.chips != 0) '+${_n(j.chips)} Chips',
      if (j.mult != 0) '+${_n(j.mult)} Mult',
      if (j.xMult != 1) 'x${_n(j.xMult)}',
      if (j.copy == JokerCopy.blueprint) 'Copy right',
      if (j.copy == JokerCopy.brainstorm) 'Copy first',
      if (j.retriggersResidue) 'Retrigger',
    ];
    return parts.join('\n');
  }

  /// A joker the registry doesn't know falls back to the Common look.
  static RarityStyle styleOf(Joker j) {
    final def = JokerRegistry.maybeById(j.id);
    return def == null ? RarityStyle.common : RarityStyle.ofRarity(def.rarity);
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final style = styleOf(joker);
    final card = RarityFrame(
      style: style,
      radius: 8,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RarityBadge(style: style, small: true),
          const SizedBox(height: 2),
          Text(
            nameOf(joker),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            effectOf(joker),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F)),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DebuffCross(active: debuffed, child: card),
    );
  }
}

class EmptyJokerSlot extends StatelessWidget {
  const EmptyJokerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
