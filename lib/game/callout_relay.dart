import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/hud_callout.dart';
import '../state/quick_play_event.dart';

/// Holds a Quick Play event (tray refund, Second Wind, Rescue) until the
/// score replay has finished, then pops it on the HUD, so "+8 TRAYS!" lands
/// after the score popups instead of over them.
class CalloutRelay {
  QuickPlayEvent _seen = QuickPlayEvent.none;
  QuickPlayEvent? _pending;

  /// Call with every state's event. A new, non-empty event becomes pending.
  void observe(QuickPlayEvent event) {
    if (identical(event, _seen)) return;
    _seen = event;
    if (!event.isEmpty) _pending = event;
  }

  /// Shows the pending event, if any, with a heavy haptic.
  void flush(ProviderContainer container) {
    final event = _pending;
    if (event == null) return;
    _pending = null;
    container.read(hudCalloutProvider.notifier).show(event);
    HapticFeedback.heavyImpact();
  }
}
