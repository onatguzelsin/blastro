import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// A quick scale-bounce on a grid cell as it scores: a bright tile pops to
/// 1.25x and settles back, then removes itself.
class CellBounceEffect extends RectangleComponent {
  CellBounceEffect({required Vector2 center, required double cell})
    : super(
        position: center,
        size: Vector2.all(cell - 2),
        anchor: Anchor.center,
        priority: 8,
        paint: Paint()..color = const Color(0x88FFFFFF),
      );

  static const double peakScale = 1.25;
  static const double halfDuration = 0.09;

  @override
  Future<void> onLoad() async {
    add(
      ScaleEffect.by(
        Vector2.all(peakScale),
        EffectController(
          duration: halfDuration,
          reverseDuration: halfDuration,
          curve: Curves.easeOut,
        ),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// Camera shake for multi-line clears.
abstract final class CameraShake {
  static const double stepSeconds = 0.045;

  /// Peak offset in dp: 3 for a double clear, +1.5 per extra line, max 10.
  static double amplitude(int lineCount) =>
      lineCount < 2 ? 0 : min(3.0 + (lineCount - 2) * 1.5, 10.0);

  /// Relative camera moves for a clear of [lineCount] lines. Empty for a
  /// single line. The moves sum to zero so the camera ends where it began.
  static List<Vector2> steps(int lineCount) {
    final a = amplitude(lineCount);
    if (a == 0) return const [];
    return [
      Vector2(a, -a * 0.5),
      Vector2(-2 * a, a),
      Vector2(2 * a, -a),
      Vector2(-a, a * 0.5),
    ];
  }

  /// Shakes the camera by adding the moves to its [viewfinder].
  static void shake(Viewfinder viewfinder, int lineCount) {
    final moves = steps(lineCount);
    if (moves.isEmpty) return;
    viewfinder.add(
      SequenceEffect([
        for (final m in moves)
          MoveByEffect(m, EffectController(duration: stepSeconds)),
      ]),
    );
  }
}
