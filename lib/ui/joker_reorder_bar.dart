import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';
import '../core/roguelite/ante_scaling.dart';
import '../state/run_state.dart';
import 'joker_bounce.dart';
import 'joker_card.dart';
import 'joker_inspect_dialog.dart';

export 'joker_bounce.dart';
export 'joker_card.dart';

/// 5-slot joker bar. Phase 4 scores strictly left to right, so dragging a
/// joker (long press) changes the order of operations.
class JokerReorderBar extends ConsumerWidget {
  const JokerReorderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jokers = ref.watch(runProvider.select((s) => s.jokers));
    // The Boss only debuffs while its round is being played.
    final boss = ref.watch(
      runProvider.select(
        (s) => s.status == RunStatus.playing && s.blind == BlindType.boss
            ? s.boss
            : null,
      ),
    );
    return SizedBox(
      height: 72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / RunState.maxJokers;
          return ReorderableListView(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            proxyDecorator: (child, _, _) =>
                Material(color: Colors.transparent, child: child),
            onReorderItem: (from, to) =>
                ref.read(runProvider.notifier).reorderJokers(from, to),
            children: [
              for (var i = 0; i < RunState.maxJokers; i++)
                SizedBox(
                  key: ValueKey(i < jokers.length ? jokers[i].id : 'empty_$i'),
                  width: slotWidth,
                  child: i < jokers.length
                      ? ReorderableDelayedDragStartListener(
                          index: i,
                          // Tap to inspect; a long press still starts a reorder.
                          child: GestureDetector(
                            onTap: () => showJokerInspect(context, jokers[i]),
                            child: JokerBounce(
                              slot: i,
                              child: JokerCard(
                                joker: jokers[i],
                                debuffed:
                                    boss?.debuffsJoker(jokers[i]) ?? false,
                              ),
                            ),
                          ),
                        )
                      : const EmptyJokerSlot(),
                ),
            ],
          );
        },
      ),
    );
  }
}
