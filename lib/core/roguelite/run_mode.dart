import '../grid/line_detector.dart';
import 'joker_effects.dart';
import 'joker_registry.dart';

/// How a run plays. Normal runs are blinds and antes; Quick Play is the
/// endless arcade mode.
enum RunMode {
  normal(traySize: 3, trayRefundPerClearedCell: 0, adaptiveDealing: false),
  quickPlay(traySize: 4, trayRefundPerClearedCell: 1, adaptiveDealing: true);

  const RunMode({
    required this.traySize,
    required this.trayRefundPerClearedCell,
    required this.adaptiveDealing,
  });

  /// Pieces dealt per tray.
  final int traySize;

  /// Extra trays granted for every cell a placement clears.
  final int trayRefundPerClearedCell;

  /// Lean toward helpful pieces when the board is crowded.
  final bool adaptiveDealing;

  bool get isQuickPlay => this == RunMode.quickPlay;

  /// Trays granted for a placement that clears [clears]: one per DISTINCT
  /// cell (a single line is +8, a Cross Clear +15, two parallel lines +16).
  int trayRefund(LineClears clears) =>
      trayRefundPerClearedCell * clears.cellCount;
}

abstract final class QuickPlay {
  /// The pre-equipped loadout, in bar order. Blueprint copies the joker to
  /// its right, so it sits first to double Grand Architect's x1.5-per-line.
  static const List<String> loadoutIds = [
    'joker_blueprint',
    'joker_grand_architect',
    'joker_cornerstone',
    'joker_heavyweight',
    'joker_streak_saver',
  ];

  static List<Joker> loadout() => [
    for (final id in loadoutIds) JokerRegistry.byId(id).joker,
  ];

  /// A Rescue always clears at least this many of the fullest rows.
  static const int rescueMinRows = 3;
}
