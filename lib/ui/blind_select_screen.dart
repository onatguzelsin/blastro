import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/blind_preview.dart';
import '../state/run_notifier.dart';
import 'blind_card.dart';
import '../core/i18n/str_keys_game.dart';
import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';

/// Shown between blinds and at the start of every Ante: the three blinds of
/// the current Ante with their status, target and reward. Covers the board.
class BlindSelectScreen extends ConsumerWidget {
  const BlindSelectScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(runProvider);
    final notifier = ref.read(runProvider.notifier);
    final cards = BlindPreviews.forAnte(
      ante: s.ante,
      seed: s.seed,
      current: s.blind,
      skipped: s.skipped.toSet(),
    );
    return Material(
      color: const Color(0xFF0F1220),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onMenu,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(t(MenuStr.menu)),
                  ),
                  const Spacer(),
                  Text(
                    '\$${s.gold}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
              Text(
                t(FlowStr.anteHeading, {'n': s.ante}),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                t(s.endless ? FlowStr.endlessMode : FlowStr.chooseBlind),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => BlindCard(
                    preview: cards[i],
                    onPlay: notifier.playBlind,
                    onSkip: notifier.skipBlind,
                  ),
                ),
              ),
              Text(
                t(FlowStr.skipWarning),
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
