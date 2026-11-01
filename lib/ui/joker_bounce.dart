import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/joker_pulse.dart';

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
