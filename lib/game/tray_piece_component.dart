import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import '../core/grid/grid_cell.dart';
import '../core/polyomino/polyomino_shape.dart';
import 'blastro_game.dart';
import 'cell_visual_renderer.dart';
import 'game_layout.dart';

/// One tray slot. Its hit area is the whole slot (easy to grab); the piece is
/// drawn centered at tray scale, and at 1.0x board-cell scale while dragged.
class TrayPieceComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<BlastroGame> {
  TrayPieceComponent(this.slot, this.layout)
    : super(
        size: layout.traySlotSize,
        position: layout.trayCenter(slot),
        anchor: Anchor.center,
      );

  final int slot;
  final GameLayout layout;
  Polyomino? piece;

  /// How this piece's cells look (every cell shares it). Plain unless the
  /// piece was given an enhancement or edition.
  GridCell cell = GridCell.plain;

  /// Animation clock in seconds, set by the game every frame.
  double time = 0;
  Vector2 _touch = Vector2.zero();

  bool get _dragging => isDragged;

  @override
  void onTapUp(TapUpEvent event) {
    if (piece != null) game.rotateSlot(slot);
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (piece == null || game.inputLocked) return;
    super.onDragStart(event);
    priority = 20;
    _touch = event.canvasPosition.clone();
    _moveToDrag();
    HapticFeedback.selectionClick();
    game.previewDrag(slot, piece!, layout.dragCenter(_touch));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    _touch = event.canvasEndPosition.clone();
    _moveToDrag();
    game.previewDrag(slot, piece!, layout.dragCenter(_touch));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final p = piece;
    if (p != null && _dragging) {
      game.dropPiece(slot, p, layout.dragCenter(_touch));
    }
    _resetToSlot();
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (_dragging) game.clearPreview();
    _resetToSlot();
    super.onDragCancel(event);
  }

  void _moveToDrag() => position = layout.dragCenter(_touch);

  void _resetToSlot() {
    priority = 0;
    position = layout.trayCenter(slot);
  }

  @override
  void render(Canvas canvas) {
    final p = piece;
    if (p == null) return;
    final cs = layout.cell * (_dragging ? 1.0 : GameLayout.trayScale);
    final origin = Offset(
      size.x / 2 - p.width * cs / 2,
      size.y / 2 - p.height * cs / 2,
    );
    for (final o in p.cells) {
      CellVisualRenderer.paint(
        canvas,
        Rect.fromLTWH(
          origin.dx + o.col * cs + 1,
          origin.dy + o.row * cs + 1,
          cs - 2,
          cs - 2,
        ),
        cell,
        time,
      );
    }
  }
}
