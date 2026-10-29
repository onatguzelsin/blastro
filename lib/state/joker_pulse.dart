import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which joker slot just scored. [tick] changes on every pulse so the same
/// slot can pulse twice in a row.
class JokerPulse {
  const JokerPulse({this.slot = -1, this.tick = 0});

  final int slot;
  final int tick;
}

final jokerPulseProvider = NotifierProvider<JokerPulseNotifier, JokerPulse>(
  JokerPulseNotifier.new,
);

class JokerPulseNotifier extends Notifier<JokerPulse> {
  @override
  JokerPulse build() => const JokerPulse();

  void pulse(int slot) => state = JokerPulse(slot: slot, tick: state.tick + 1);
}
