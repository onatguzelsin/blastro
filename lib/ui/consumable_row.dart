import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/consumables.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// The (up to 2) held consumables, each with a Use button. Shared by the
/// shop and the Bag modal.
class ConsumableRow extends ConsumerWidget {
  const ConsumableRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
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
                    strings,
                    i,
                    ConsumableRegistry.byId(s.consumables[i]),
                    usable,
                  )
                : _empty(strings),
          ),
        ],
      ],
    );
  }

  Widget _card(
    WidgetRef ref,
    AppStrings strings,
    int index,
    Consumable card,
    bool usable,
  ) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF1E2433),
      border: Border.all(color: const Color(0xFF40C4FF)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          strings.nameOf(card.id, card.name),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          strings.descriptionOf(card.id, card.description),
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
          child: Text(strings.t(FlowStr.use)),
        ),
      ],
    ),
  );

  Widget _empty(AppStrings strings) => Container(
    height: 96,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      strings.t(FlowStr.emptySlot),
      style: const TextStyle(fontSize: 11, color: Colors.white38),
    ),
  );
}
