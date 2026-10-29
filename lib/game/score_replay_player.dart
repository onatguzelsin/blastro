import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../core/scoring/score_step_event.dart';
import 'game_layout.dart';
import 'haptic_throttle.dart';
import 'juice_effects.dart';
import 'score_popup_effect.dart';

/// Replays a `List<ScoreStepEvent>` one step at a time: each step updates the
/// live Chips x Mult totals, spawns a floating popup and fires a haptic.
class ScoreReplayPlayer extends Component {
  ScoreReplayPlayer({
    required this.layout,
    required this.popupParent,
    required this.onTotals,
    required this.onDone,
    required this.onJokerPulse,
  });

  final GameLayout layout;
  final Component popupParent;
  final void Function(double chips, double mult) onTotals;
  final void Function() onDone;

  /// A joker's step is playing: bounce its card in the overlay bar.
  final void Function(int slot) onJokerPulse;
  final HapticThrottle _haptics = HapticThrottle();

  List<ScoreStepEvent> _events = const [];
  int _next = 0;
  double _clock = 0;
  double _step = 0.07;
  double _time = 0;

  bool get isPlaying => _next < _events.length;

  void play(List<ScoreStepEvent> events) {
    _events = events;
    _next = 0;
    // Long replays (Clean Sweeps) speed up to stay around two seconds.
    _step = min(0.07, max(0.025, 2.0 / max(1, events.length)));
    _clock = _step;
    _time = 0;
    _haptics.reset();
  }

  void cancel() {
    _events = const [];
    _next = 0;
  }

  @override
  void update(double dt) {
    if (!isPlaying) return;
    _clock += dt;
    _time += dt;
    while (_clock >= _step && isPlaying) {
      _clock -= _step;
      _emit(_events[_next++]);
    }
    if (!isPlaying) {
      _events = const [];
      onDone();
    }
  }

  void _emit(ScoreStepEvent e) {
    onTotals(e.totalChips, e.totalMult);
    if (_haptics.shouldFire(e.haptic, _time)) {
      switch (e.haptic) {
        case HapticIntensity.light:
          HapticFeedback.lightImpact();
        case HapticIntensity.medium:
          HapticFeedback.mediumImpact();
        case HapticIntensity.heavy:
          HapticFeedback.heavyImpact();
        case HapticIntensity.none:
          break;
      }
    }
    final row = e.row, col = e.col;
    if (row != null && col != null) {
      popupParent.add(
        CellBounceEffect(
          center: layout.cellCenter(row, col),
          cell: layout.cell,
        ),
      );
    }
    final slot = e.jokerIndex;
    if (slot != null) onJokerPulse(slot);
    final text = ScorePopupEffect.textFor(e);
    if (text == null) return;
    popupParent.add(
      ScorePopupEffect(
        text: text,
        color: ScorePopupEffect.colorFor(e),
        origin: _originFor(e),
        fontSize: e.kind == ScoreStepKind.finalScore ? 32 : 18,
      ),
    );
  }

  Vector2 _originFor(ScoreStepEvent e) {
    final row = e.row, col = e.col;
    if (row != null && col != null) return layout.cellCenter(row, col);
    final jokerIndex = e.jokerIndex;
    if (jokerIndex != null) {
      final x =
          layout.boardOrigin.x + layout.boardSide * (0.12 + 0.19 * jokerIndex);
      return Vector2(x, layout.boardOrigin.y - 6);
    }
    return layout.boardCenter;
  }
}
