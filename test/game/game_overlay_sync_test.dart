import 'package:blastro/game/game_overlay_sync.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A game with a builder registered for every overlay, as GameWidget does.
FlameGame _game() {
  final game = FlameGame();
  for (final name in [
    GameOverlays.hud,
    GameOverlays.runOver,
    GameOverlays.cashOut,
    GameOverlays.shop,
    GameOverlays.bag,
    GameOverlays.victory,
    GameOverlays.blindSelect,
  ]) {
    game.overlays.addEntry(name, (context, game) => const SizedBox());
  }
  return game;
}

Set<String> _sync(FlameGame game, RunStatus status) {
  GameOverlays.sync(game, status);
  return game.overlays.activeOverlays.toSet();
}

void main() {
  test('each status shows exactly its own screen', () {
    final expected = {
      RunStatus.blindSelect: GameOverlays.blindSelect,
      RunStatus.blindCleared: GameOverlays.cashOut,
      RunStatus.shopping: GameOverlays.shop,
      RunStatus.victory: GameOverlays.victory,
    };
    for (final e in expected.entries) {
      expect(_sync(_game(), e.key), {e.value}, reason: e.key.name);
    }
  });

  test('playing shows no status screen; losing shows Run Over', () {
    expect(_sync(_game(), RunStatus.playing), isEmpty);
    expect(_sync(_game(), RunStatus.lost), {GameOverlays.runOver});
  });

  test('the full flow swaps screens without leaving one behind', () {
    final game = _game();
    expect(_sync(game, RunStatus.playing), isEmpty);
    expect(_sync(game, RunStatus.blindCleared), {GameOverlays.cashOut});
    expect(_sync(game, RunStatus.shopping), {GameOverlays.shop});
    expect(_sync(game, RunStatus.blindSelect), {GameOverlays.blindSelect});
    expect(_sync(game, RunStatus.playing), isEmpty);
  });

  test('victory then endless cash out replaces the Victory sheet', () {
    final game = _game();
    _sync(game, RunStatus.victory);
    expect(_sync(game, RunStatus.blindCleared), {GameOverlays.cashOut});
  });

  test('the Bag closes when the hub opens, and on a new run', () {
    final game = _game()..overlays.add(GameOverlays.bag);
    expect(_sync(game, RunStatus.blindSelect), {GameOverlays.blindSelect});
    game.overlays.add(GameOverlays.bag);
    GameOverlays.clearAll(game);
    expect(game.overlays.activeOverlays, isEmpty);
  });

  test('the HUD overlay is never removed by status changes', () {
    final game = _game()..overlays.add(GameOverlays.hud);
    for (final s in RunStatus.values) {
      GameOverlays.sync(game, s);
      expect(game.overlays.isActive(GameOverlays.hud), isTrue, reason: s.name);
    }
  });
}
