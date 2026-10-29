import '../core/scoring/score_step_event.dart';

/// Keeps a long scoring chain from buzzing on every step: at most one haptic
/// per [minGap] seconds, unless the intensity escalates past the last one.
class HapticThrottle {
  HapticThrottle({this.minGap = 0.06});

  final double minGap;
  double _lastTime = -1e9;
  HapticIntensity _last = HapticIntensity.none;

  /// Whether a haptic of [intensity] should fire at [now] (seconds).
  bool shouldFire(HapticIntensity intensity, double now) {
    if (intensity == HapticIntensity.none) return false;
    final escalates = intensity.index > _last.index;
    if (!escalates && now - _lastTime < minGap) return false;
    _lastTime = now;
    _last = intensity;
    return true;
  }

  void reset() {
    _lastTime = -1e9;
    _last = HapticIntensity.none;
  }
}
