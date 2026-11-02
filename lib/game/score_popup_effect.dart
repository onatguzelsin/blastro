import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/scoring/score_step_event.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../core/i18n/supported_language.dart';

/// Floating score text that drifts up and fades out, then removes itself.
class ScorePopupEffect extends PositionComponent {
  ScorePopupEffect({
    required this.text,
    required this.color,
    required Vector2 origin,
    this.fontSize = 18,
    this.lifetime = 0.9,
  }) : super(position: origin.clone(), anchor: Anchor.center, priority: 50);

  final String text;
  final Color color;
  final double fontSize;
  final double lifetime;
  double _age = 0;

  /// Popup label for a replay step; null for steps that show nothing.
  static String? textFor(ScoreStepEvent e, [AppStrings? strings]) {
    final s = strings ?? AppStrings(Languages.english);
    if (e.kind == ScoreStepKind.finalScore) {
      return e.label.replaceFirst('final ', '');
    }
    if (e.flatBonus > 0) return '+${e.flatBonus}';
    if (e.multFactor > 1) return 'x${_trim(e.multFactor)}';
    if (e.multDelta > 0) {
      return s.t(HudStr.popupMult, {'n': _trim(e.multDelta)});
    }
    if (e.chipsDelta > 0) return '+${_trim(e.chipsDelta)}';
    return null;
  }

  static Color colorFor(ScoreStepEvent e) {
    if (e.kind == ScoreStepKind.finalScore) return const Color(0xFFFFD54F);
    if (e.flatBonus > 0) return const Color(0xFFFFD54F);
    if (e.multFactor > 1 || e.multDelta > 0) return const Color(0xFFFF5252);
    return const Color(0xFF40C4FF);
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void update(double dt) {
    _age += dt;
    position.y -= 46 * dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / lifetime).clamp(0.0, 1.0);
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: const Color(0xFF000000).withValues(alpha: alpha),
            blurRadius: 3,
          ),
        ],
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
