import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/joker_effects.dart';
import '../core/roguelite/joker_registry.dart';
import '../state/joker_pulse.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';

/// 5-slot joker bar. Phase 4 scores strictly left to right, so dragging a
/// joker (long press) changes the order of operations.
class JokerReorderBar extends ConsumerWidget {
  const JokerReorderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jokers = ref.watch(runProvider.select((s) => s.jokers));
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
                          child: JokerBounce(
                            slot: i,
                            child: JokerCard(joker: jokers[i]),
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

class JokerCard extends StatelessWidget {
  const JokerCard({super.key, required this.joker});

  final Joker joker;

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

  static String _n(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A5C),
        border: Border.all(color: const Color(0xFFB388FF), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nameOf(joker),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            effectOf(joker),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F)),
          ),
        ],
      ),
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

/// Scale-bounces its child whenever its slot scores during a replay.
class JokerBounce extends ConsumerStatefulWidget {
  const JokerBounce({super.key, required this.slot, required this.child});

  final int slot;
  final Widget child;

  @override
  ConsumerState<JokerBounce> createState() => _JokerBounceState();
}

class _JokerBounceState extends ConsumerState<JokerBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.18,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.18,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(jokerPulseProvider, (_, pulse) {
      if (pulse.slot == widget.slot) _controller.forward(from: 0);
    });
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
