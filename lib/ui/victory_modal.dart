import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/ante_scaling.dart';
import '../state/run_notifier.dart';
import 'slide_up_sheet.dart';

/// Shown when the Ante 8 Finisher falls. Continuing keeps the whole run
/// (jokers, bag, cards, bankroll) and heads into Endless Mode.
class VictoryModal extends ConsumerWidget {
  const VictoryModal({super.key, required this.onNewRun});

  final VoidCallback onNewRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    return SlideUpSheet(
      title: 'Victory!',
      child: Column(
        children: [
          const Text(
            'You defeated the Ante 8 Finisher.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          _stat('Final score', '${s.score}'),
          _stat('Jokers', '${s.jokers.length}/5'),
          _stat('Bankroll', '\$${s.gold}'),
          const SizedBox(height: 8),
          Text(
            'Endless Mode runs Antes 9 to ${AnteScaling.lastEndlessAnte} '
            'with the same jokers, bag and bankroll.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(runProvider.notifier).enterEndless(),
              child: const Text('Continue to Endless Mode'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onNewRun,
              child: const Text('Start New Run'),
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
