import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/hud_callout.dart';

/// The floating "+8 TRAYS!" (and "SECOND WIND!", "RESCUE!") that pops over the
/// HUD, drifts up and fades. Restarts on every new [HudCallout].
class FloatingCallout extends ConsumerStatefulWidget {
  const FloatingCallout({super.key});

  static const Duration duration = Duration(milliseconds: 1600);

  @override
  ConsumerState<FloatingCallout> createState() => _FloatingCalloutState();
}

class _FloatingCalloutState extends ConsumerState<FloatingCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: FloatingCallout.duration,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(hudCalloutProvider, (_, next) => _c.forward(from: 0));
    final callout = ref.watch(hudCalloutProvider);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (callout.lines.isEmpty || t == 0 || t == 1) {
            return const SizedBox.shrink();
          }
          // Pop in with an overshoot, hold, then fade while drifting upward.
          final scale = t < 0.2
              ? 0.5 + 0.75 * (t / 0.2)
              : 1.25 - 0.25 * min(1, (t - 0.2) / 0.15);
          final opacity = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -42 * t),
              child: Transform.scale(
                scale: scale,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < callout.lines.length; i++)
                        Text(
                          callout.lines[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: i == 0 ? 32 : 17,
                            fontWeight: FontWeight.w900,
                            color: i == 0
                                ? const Color(0xFF69F0AE)
                                : const Color(0xFFFFD54F),
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 6),
                              Shadow(color: Colors.black, blurRadius: 12),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
