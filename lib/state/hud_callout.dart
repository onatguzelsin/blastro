import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quick_play_event.dart';
import 'locale_provider.dart';

/// The floating text on the HUD ("+8 TRAYS!"). [tick] changes on every show so
/// the same text can pop twice in a row.
class HudCallout {
  const HudCallout({this.lines = const [], this.tick = 0});

  final List<String> lines;
  final int tick;
}

final hudCalloutProvider = NotifierProvider<HudCalloutNotifier, HudCallout>(
  HudCalloutNotifier.new,
);

class HudCalloutNotifier extends Notifier<HudCallout> {
  @override
  HudCallout build() => const HudCallout();

  void show(QuickPlayEvent event) {
    if (event.isEmpty) return;
    state = HudCallout(
      lines: event.callouts(ref.read(stringsProvider)),
      tick: state.tick + 1,
    );
  }
}
