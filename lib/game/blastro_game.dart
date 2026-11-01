import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/polyomino/polyomino_shape.dart';
import '../core/roguelite/ante_scaling.dart';
import '../state/joker_pulse.dart';
import '../state/placement_preview.dart';
import '../state/replay_totals.dart';
import '../state/run_notifier.dart';
import '../state/run_placement.dart';
import '../state/run_state.dart';
import 'board_component.dart';
import 'board_highlight.dart';
import 'game_layout.dart';
import 'game_overlay_sync.dart';
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

  static const runOverOverlay = GameOverlays.runOver;
  static const cashOutOverlay = GameOverlays.cashOut;
  static const shopOverlay = GameOverlays.shop;
  static const bagOverlay = GameOverlays.bag;
  static const victoryOverlay = GameOverlays.victory;
  static const blindSelectOverlay = GameOverlays.blindSelect;

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
  bool _loaded = false;
  double _clock = 0;

  /// The (slot, row, col) last previewed, so a hover that has not moved to a
  /// new cell does no work.
  (int, int, int)? _previewKey;

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
    _loaded = true;
    _subscription = container.listen(
      runProvider,
      (_, next) => _onState(next),
      fireImmediately: true,
    );
  }

  /// Advances the clock that animates special cells on the board and tray.
  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    _clock += dt;
    _board.time = _clock;
    _tray.time = _clock;
  }

  @override
  void onRemove() {
    _subscription?.close();
    super.onRemove();
  }

  void _onState(RunState s) {
    _tray.sync(s.tray);
    _board.boss = s.status == RunStatus.playing && s.blind == BlindType.boss
        ? s.boss
        : null;
    final result = s.lastScore;
    if (s.scoreSerial < _handledSerial) {
      // New run: drop any in-flight replay and overlay.
      _handledSerial = s.scoreSerial;
      _replay.cancel();
      inputLocked = false;
      GameOverlays.clearAll(this);
      container.read(replayTotalsProvider.notifier).set(0, 0);
    } else if (s.scoreSerial > _handledSerial && result != null) {
      _handledSerial = s.scoreSerial;
      clearPreview();
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
      GameOverlays.sync(this, s.status);
    }
  }

  void _finishReplay() {
    inputLocked = false;
    _board.grid = _state.grid;
    GameOverlays.sync(this, _state.status);
  }

  /// Called every frame of a drag with the dragged piece's center. The ghost
  /// follows every frame; the score preview is recalculated only when the
  /// piece snaps to a different cell.
  void previewDrag(int slot, Polyomino piece, Vector2 center) {
    final at = layout.snap(center, piece);
    _highlight.preview(_state.grid, piece, at.row, at.col);
    final key = (slot, at.row, at.col);
    if (key == _previewKey) return;
    _previewKey = key;
    final sim = RunPlacement.preview(_state, slot, at.row, at.col);
    container.read(placementPreviewProvider.notifier).show(sim?.summary);
  }

  /// Drops the ghost, the pulsing lines and the HUD score preview.
  void clearPreview() {
    _highlight.clear();
    _previewKey = null;
    container.read(placementPreviewProvider.notifier).clear();
  }

  /// Drop: place if legal (state change redraws everything), else the tray
  /// piece just snaps back.
  void dropPiece(int slot, Polyomino piece, Vector2 center) {
    clearPreview();
    final at = layout.snap(center, piece);
    if (_notifier.placePiece(slot, at.row, at.col)) {
      HapticFeedback.lightImpact();
    }
  }

  /// "New Run" buttons: a fresh run that starts at the Blind Select hub.
  void startNewRun() => _notifier.startRun();

  /// Gyroscope: tap a tray piece to rotate it.
  void rotateSlot(int slot) {
    if (!inputLocked) _notifier.rotateTraySlot(slot);
  }
}
