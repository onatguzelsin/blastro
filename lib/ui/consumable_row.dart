import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/consumables.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';

/// The (up to 2) held consumables, each with a Use button. Shared by the
/// shop and the Bag modal.
class ConsumableRow extends ConsumerWidget {
  const ConsumableRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    final usable =
        s.status == RunStatus.playing || s.status == RunStatus.shopping;
    return Row(
      children: [
        for (var i = 0; i < Consumable.maxHeld; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: i < s.consumables.length
                ? _card(
                    ref,
                    i,
                    ConsumableRegistry.byId(s.consumables[i]),
                    usable,
                  )
                : _empty(),
          ),
        ],
      ],
    );
  }

  Widget _card(WidgetRef ref, int index, Consumable card, bool usable) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          border: Border.all(color: const Color(0xFF40C4FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              card.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: usable
                  ? () => ref.read(runProvider.notifier).useConsumable(index)
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(30),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Use'),
            ),
          ],
        ),
      );

  Widget _empty() => Container(
    height: 96,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'Empty slot',
      style: TextStyle(fontSize: 11, color: Colors.white38),
    ),
  );
}
