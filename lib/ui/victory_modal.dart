import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/ante_scaling.dart';
import '../state/run_notifier.dart';
import 'slide_up_sheet.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// Shown when the Ante 8 Finisher falls. Continuing keeps the whole run
/// (jokers, bag, cards, bankroll) and heads into Endless Mode.
class VictoryModal extends ConsumerWidget {
  const VictoryModal({super.key, required this.onNewRun});

  final VoidCallback onNewRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(runProvider);
    return SlideUpSheet(
      title: t(FlowStr.victoryTitle),
      child: Column(
        children: [
          Text(
            t(FlowStr.victoryBody),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          _stat(t(FlowStr.victoryFinal), '${s.score}'),
          _stat(t(FlowStr.victoryJokers), '${s.jokers.length}/5'),
          _stat(t(FlowStr.victoryBankroll), '\$${s.gold}'),
          const SizedBox(height: 8),
          Text(
            t(FlowStr.victoryEndless, {'last': AnteScaling.lastEndlessAnte}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(runProvider.notifier).enterEndless(),
              child: Text(t(FlowStr.victoryContinue)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onNewRun,
              child: Text(t(FlowStr.victoryNew)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD54F),
          ),
        ),
      ],
    ),
  );
}
