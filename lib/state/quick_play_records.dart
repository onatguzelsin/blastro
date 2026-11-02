import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_persistence.dart';

/// The best Quick Play score ever reached (saved on the device).
final quickPlayBestProvider = NotifierProvider<QuickPlayBestNotifier, int>(
  QuickPlayBestNotifier.new,
);

class QuickPlayBestNotifier extends Notifier<int> {
  @override
  int build() => ref.read(runPersistenceProvider)?.bestQuickPlayScore ?? 0;

  /// Keeps the highest score seen, and saves it when it is a new best.
  void record(int score) {
    if (score <= state) return;
    state = score;
    ref.read(runPersistenceProvider)?.saveBestQuickPlayScore(score);
  }
}
