import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/polyomino/polyomino_shape.dart';
import '../state/joker_pulse.dart';
import '../state/replay_totals.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';
import 'board_component.dart';
import 'board_highlight.dart';
import 'game_layout.dart';
import 'juice_effects.dart';
import 'score_replay_player.dart';
import 'tray_component.dart';

/// Flame view of the run. All rules live in [RunNotifier]; this class only
/// renders state, forwards drops, and replays score events.
class BlastroGame extends FlameGame {
  BlastroGame({
    required this.container,
    this.topInset = 0,
    this.bottomInset = 0,
  });

  static const runOverOverlay = 'runOver';
  static const cashOutOverlay = 'cashOut';
  static const shopOverlay = 'shop';
  static const bagOverlay = 'bag';
  static const victoryOverlay = 'victory';

  final ProviderContainer container;
  final double topInset;
  final double bottomInset;

  late final GameLayout layout;
  late final BoardComponent _board;
  late final BoardHighlight _highlight;
  late final TrayComponent _tray;
  late final ScoreReplayPlayer _replay;
  ProviderSubscription<RunState>? _subscription;
  int _handledSerial = 0;

  /// True while a score replay plays; new drags are ignored.
  bool inputLocked = false;

  RunNotifier get _notifier => container.read(runProvider.notifier);
  RunState get _state => container.read(runProvider);

  @override
  Color backgroundColor() => const Color(0xFF0F1220);

  @override
  Future<void> onLoad() async {
    // Anchor the camera top-left so world coordinates equal screen
    // coordinates; shaking the viewfinder then shakes the whole board.
    camera.viewfinder.anchor = Anchor.topLeft;
    layout = GameLayout.compute(
      size,
      topInset: topInset,
      bottomInset: bottomInset,
    );
    _board = BoardComponent(layout, _state.grid);
    _highlight = BoardHighlight(layout);
    _tray = TrayComponent(layout);
    _replay = ScoreReplayPlayer(
      layout: layout,
      popupParent: world,
      onTotals: (c, m) =>
          container.read(replayTotalsProvider.notifier).set(c, m),
      onDone: _finishReplay,
      onJokerPulse: (slot) =>
          container.read(jokerPulseProvider.notifier).pulse(slot),
    );
    await world.addAll([_board, _highlight, _tray, _replay]);
    _subscription = container.listen(
      runProvider,
      (_, next) => _onState(next),
      fireImmediately: true,
    );
  }

  @override
  void onRemove() {
    _subscription?.close();
    super.onRemove();
  }

  void _onState(RunState s) {
    _tray.sync(s.tray);
    final result = s.lastScore;
    if (s.scoreSerial < _handledSerial) {
      // New run: drop any in-flight replay and overlay.
      _handledSerial = s.scoreSerial;
      _replay.cancel();
      inputLocked = false;
      overlays.removeAll([
        runOverOverlay,
        cashOutOverlay,
        shopOverlay,
        bagOverlay,
        victoryOverlay,
      ]);
      container.read(replayTotalsProvider.notifier).set(0, 0);
    } else if (s.scoreSerial > _handledSerial && result != null) {
      _handledSerial = s.scoreSerial;
      _highlight.clear();
      if (result.events.isNotEmpty) {
        inputLocked = true;
        _board.grid = s.preClearBoard ?? s.grid;
        CameraShake.shake(camera.viewfinder, result.clears.lineCount);
        _replay.play(result.events);
        return;
      }
    }
    if (!_replay.isPlaying && !inputLocked) {
      _board.grid = s.grid;
      _syncOverlays(s);
    }
  }

  void _finishReplay() {
    inputLocked = false;
    _board.grid = _state.grid;
    _syncOverlays(_state);
  }

  /// Run status drives the sheets: cash out -> shop -> back to the board.
  /// Driving it from state also restores the right sheet after a relaunch.
  void _syncOverlays(RunState s) {
    switch (s.status) {
      case RunStatus.lost:
        overlays.add(runOverOverlay);
      case RunStatus.victory:
        overlays.add(victoryOverlay);
      case RunStatus.blindCleared:
        overlays
          ..remove(victoryOverlay)
          ..add(cashOutOverlay);
      case RunStatus.shopping:
        overlays
          ..remove(cashOutOverlay)
          ..add(shopOverlay);
      case RunStatus.playing:
        overlays.removeAll([
          runOverOverlay,
          cashOutOverlay,
          shopOverlay,
          victoryOverlay,
        ]);
    }
  }

  /// Called every frame of a drag with the dragged piece's center.
  void previewDrag(int slot, Polyomino piece, Vector2 center) {
    final at = layout.snap(center, piece);
    _highlight.preview(_state.grid, piece, at.row, at.col);
  }

  void clearPreview() => _highlight.clear();

  /// Drop: place if legal (state change redraws everything), else the tray
  /// piece just snaps back.
  void dropPiece(int slot, Polyomino piece, Vector2 center) {
    _highlight.clear();
    final at = layout.snap(center, piece);
    if (_notifier.placePiece(slot, at.row, at.col)) {
      HapticFeedback.lightImpact();
    }
  }

  void startNewRun() => _notifier.newRun();

  /// Gyroscope: tap a tray piece to rotate it.
  void rotateSlot(int slot) {
    if (!inputLocked) _notifier.rotateTraySlot(slot);
  }
}
