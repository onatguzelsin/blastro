import 'package:flutter/material.dart';

import '../core/roguelite/joker_effects.dart';
import '../core/roguelite/joker_registry.dart';
import 'joker_card.dart';
import 'rarity_badge.dart';
import 'rarity_frame.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_game.dart';
import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';

/// Tap an owned joker to see what it does, its rarity and what it sells for.
Future<void> showJokerInspect(BuildContext context, Joker joker) =>
    showDialog<void>(
      context: context,
      builder: (context) => JokerInspectDialog(joker: joker),
    );

class JokerInspectDialog extends ConsumerWidget {
  const JokerInspectDialog({super.key, required this.joker});

  final Joker joker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final def = JokerRegistry.maybeById(joker.id);
    final style = JokerCard.styleOf(joker);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: RarityFrame(
          style: style,
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      JokerCard.nameOf(joker, strings),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  RarityBadge(style: style),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                def == null
                    ? JokerCard.effectOf(joker, strings)
                    : strings.descriptionOf(def.id, def.description),
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
              if (def != null) ...[
                const SizedBox(height: 10),
                Text(
                  strings.t(FlowStr.sellsFor, {'n': def.sellValue}),
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.t(MenuStr.close)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
