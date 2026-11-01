import 'package:flame/game.dart';

import '../state/run_state.dart';

/// Names of the Flutter overlays on top of the Flame canvas, and which of
/// them each run status shows. Driving overlays from state also restores the
/// right screen after the app is relaunched.
abstract final class GameOverlays {
  static const hud = 'hud';
  static const runOver = 'runOver';
  static const cashOut = 'cashOut';
  static const shop = 'shop';
  static const bag = 'bag';
  static const victory = 'victory';
  static const blindSelect = 'blindSelect';

  /// Every overlay a run status can own (the HUD and Bag are not status-owned
  /// except that the Bag closes on a new run).
  static const List<String> _statusOwned = [
    runOver,
    cashOut,
    shop,
    victory,
    blindSelect,
  ];

  /// Drops every status overlay and the Bag (a new run starts clean).
  static void clearAll(FlameGame game) =>
      game.overlays.removeAll([..._statusOwned, bag]);

  /// Shows the overlay for [status] and hides the ones it replaces.
  static void sync(FlameGame game, RunStatus status) {
    final overlays = game.overlays;
    switch (status) {
      case RunStatus.blindSelect:
        _only(game, blindSelect);
        overlays.remove(bag);
      case RunStatus.playing:
        _only(game, null);
      case RunStatus.blindCleared:
        _only(game, cashOut);
      case RunStatus.shopping:
        _only(game, shop);
      case RunStatus.victory:
        _only(game, victory);
      case RunStatus.lost:
        overlays.add(runOver);
    }
  }

  /// Shows [keep] (if any) and removes every other status overlay.
  static void _only(FlameGame game, String? keep) {
    final overlays = game.overlays;
    for (final name in _statusOwned) {
      if (name != keep) overlays.remove(name);
    }
    if (keep != null) overlays.add(keep);
  }
}
