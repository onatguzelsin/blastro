/// 3-placement Combo Window. A clearing placement increments the streak; up
/// to 2 consecutive non-clearing "setup" placements keep it alive and the 3rd
/// consecutive non-clearing placement resets it to 0.
class ComboWindow {
  const ComboWindow({this.streak = 0, this.missesInARow = 0});

  static const int maxSetupMoves = 2;

  final int streak;
  final int missesInARow;

  /// State after a placement. For a clearing placement, score it with
  /// `afterPlacement(cleared: true).streak` (the incremented, active streak).
  ///
  /// [extraSetupMoves] widens the window (the Streak Saver joker).
  ComboWindow afterPlacement({required bool cleared, int extraSetupMoves = 0}) {
    if (cleared) return ComboWindow(streak: streak + 1);
    final misses = missesInARow + 1;
    if (misses > maxSetupMoves + extraSetupMoves) return const ComboWindow();
    return ComboWindow(streak: streak, missesInARow: misses);
  }

  Map<String, int> toJson() => {'streak': streak, 'misses': missesInARow};

  factory ComboWindow.fromJson(Map<String, dynamic> json) => ComboWindow(
    streak: json['streak'] as int,
    missesInARow: json['misses'] as int,
  );
}
