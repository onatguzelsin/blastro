import 'package:flutter/material.dart';

import '../core/roguelite/joker_effects.dart';
import '../core/roguelite/joker_registry.dart';
import 'debuff_cross.dart';
import 'rarity_badge.dart';
import 'rarity_frame.dart';
import 'rarity_style.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/supported_language.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// A joker in the 5-slot bar, in its rarity's colors: tinted background,
/// glowing border and a rarity pill. A debuffed joker (by the active Boss)
/// is dimmed with a red cross.
class JokerCard extends ConsumerWidget {
  const JokerCard({super.key, required this.joker, this.debuffed = false});

  final Joker joker;

  /// The active Boss switches this joker off.
  final bool debuffed;

  static AppStrings _english() => AppStrings(Languages.english);

  static String nameOf(Joker j, [AppStrings? strings]) {
    final def = JokerRegistry.maybeById(j.id);
    if (def == null) {
      return j.id.replaceFirst('joker_', '').replaceAll('_', ' ');
    }
    return (strings ?? _english()).nameOf(def.id, def.name);
  }

  /// The card's one-liner (`+4 Mult`), translated.
  static String effectOf(Joker j, [AppStrings? strings]) {
    final s = strings ?? _english();
    final def = JokerRegistry.maybeById(j.id);
    if (def != null) return s.shortOf(def.id, def.short);
    final parts = [
      if (j.chips != 0) '+${_n(j.chips)} Chips',
      if (j.mult != 0) '+${_n(j.mult)} Mult',
      if (j.xMult != 1) 'x${_n(j.xMult)}',
      if (j.copy == JokerCopy.blueprint) s.t(HudStr.copyRight),
      if (j.copy == JokerCopy.brainstorm) s.t(HudStr.copyFirst),
      if (j.retriggersResidue) s.t(HudStr.retrigger),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
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
            nameOf(joker, strings),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            effectOf(joker, strings),
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
