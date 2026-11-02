import 'dart:ui' as ui;

import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/game/tray_component.dart';
import 'package:blastro/game/tray_piece_component.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

const _screens = [
  Size(360, 740),
  Size(360, 800),
  Size(411, 914),
  Size(430, 932),
];

GameLayout _layout(Size s, int slots) => GameLayout.compute(
  Vector2(s.width, s.height),
  topInset: 24,
  bottomInset: 16,
  traySlots: slots,
);

/// Where [piece] is drawn in slot [i]: centred in the slot at its tray scale.
Rect _drawn(GameLayout l, int i, piece) {
  final scale = l.trayScaleFor(piece);
  final c = l.trayCenter(i);
  final w = piece.width * l.cell * scale, h = piece.height * l.cell * scale;
  return Rect.fromCenter(center: Offset(c.x, c.y), width: w, height: h);
}

Rect _slot(GameLayout l, int i) {
  final c = l.trayCenter(i);
  final s = l.traySlotSize;
  return Rect.fromCenter(center: Offset(c.x, c.y), width: s.x, height: s.y);
}

void main() {
  group('3 slots (normal runs) are exactly as before', () {
    test('every shape is drawn at the same 0.5x', () {
      final l = _layout(const Size(411, 914), 3);
      for (final p in PolyominoCatalog.all) {
        expect(l.trayScaleFor(p), GameLayout.trayScale, reason: p.id);
      }
    });

    test('three slots, each a third of the board width', () {
      final l = _layout(const Size(411, 914), 3);
      expect(l.traySlots, 3);
      expect(l.traySlotSize.x, closeTo(l.boardSide / 3, 1e-3));
      expect(GameLayout.defaultTraySlots, 3);
    });

    test('the default is 3 slots', () {
      final l = GameLayout.compute(Vector2(400, 800));
      expect(l.traySlots, 3);
    });
  });

  group('4 slots (Quick Play) fit cleanly', () {
    for (final screen in _screens) {
      test('${screen.width.toInt()}x${screen.height.toInt()}: every shape '
          'stays inside its own slot', () {
        final l = _layout(screen, 4);
        for (var i = 0; i < 4; i++) {
          for (final p in PolyominoCatalog.all) {
            final drawn = _drawn(l, i, p);
            final slot = _slot(l, i);
            const eps = 1e-3; // Vector2 is float32
            final reason = '${p.id} in slot $i';
            expect(
              drawn.left,
              greaterThanOrEqualTo(slot.left - eps),
              reason: reason,
            );
            expect(
              drawn.right,
              lessThanOrEqualTo(slot.right + eps),
              reason: reason,
            );
            expect(
              drawn.top,
              greaterThanOrEqualTo(slot.top - eps),
              reason: reason,
            );
            expect(
              drawn.bottom,
              lessThanOrEqualTo(slot.bottom + eps),
              reason: reason,
            );
          }
        }
      });

      test('${screen.width.toInt()}x${screen.height.toInt()}: neighbouring '
          'pieces never overlap, even two 5-wide bars side by side', () {
        final l = _layout(screen, 4);
        final bar = PolyominoCatalog.byId('bar5_h');
        for (var i = 0; i < 3; i++) {
          final a = _drawn(l, i, bar);
          final b = _drawn(l, i + 1, bar);
          expect(a.overlaps(b), isFalse);
          // Width-limited bars leave the 5% margin between neighbours.
          final margin = l.traySlotSize.x * (1 - GameLayout.slotFill);
          expect(b.left - a.right, closeTo(margin, 1e-3));
        }
      });
    }

    test('the slots tile the board width with no gaps or overlaps', () {
      final l = _layout(const Size(411, 914), 4);
      expect(_slot(l, 0).left, closeTo(l.boardOrigin.x, 1e-3));
      expect(_slot(l, 3).right, closeTo(l.boardOrigin.x + l.boardSide, 1e-3));
      for (var i = 0; i < 3; i++) {
        expect(_slot(l, i).right, closeTo(_slot(l, i + 1).left, 1e-3));
      }
      expect(l.traySlotSize.x, closeTo(l.boardSide / 4, 1e-3));
    });

    test('big pieces shrink to fit, small ones keep the normal size', () {
      final l = _layout(const Size(411, 914), 4);
      final wide = l.trayScaleFor(PolyominoCatalog.byId('bar5_h'));
      expect(wide, lessThan(GameLayout.trayScale));
      expect(wide, greaterThan(0.3), reason: 'still readable');
      for (final id in ['dot', 'bar2_h', 'rect_2x2', 'bar3_h', 'tee']) {
        expect(
          l.trayScaleFor(PolyominoCatalog.byId(id)),
          GameLayout.trayScale,
          reason: id,
        );
      }
    });

    test('the tray and the board still fit the screen', () {
      for (final screen in _screens) {
        final l = _layout(screen, 4);
        expect(l.trayTop + l.trayHeight, lessThanOrEqualTo(screen.height - 16));
        expect(l.trayCenter(3).x, lessThan(screen.width));
      }
    });

    test('dragging is unchanged: 1.0x, 80dp above the finger', () {
      final l = _layout(const Size(411, 914), 4);
      expect(l.dragCenter(Vector2(100, 500)), Vector2(100, 420));
    });
  });

  group('the tray component', () {
    test('builds one slot per tray piece', () {
      expect(TrayComponent(_layout(const Size(411, 914), 4)).slots.length, 4);
      expect(TrayComponent(_layout(const Size(411, 914), 3)).slots.length, 3);
    });

    test('syncs all four pieces', () {
      final tray = TrayComponent(_layout(const Size(411, 914), 4));
      tray.sync([
        PolyominoCatalog.byId('dot'),
        null,
        PolyominoCatalog.byId('plus'),
        PolyominoCatalog.byId('bar5_h'),
      ]);
      expect(tray.slots.map((s) => s.piece?.id), [
        'dot',
        null,
        'plus',
        'bar5_h',
      ]);
    });
  });

  group('what is actually painted', () {
    testWidgets('a 5-wide bar leaves a margin on both sides of its slot', (
      t,
    ) async {
      final l = _layout(const Size(411, 914), 4);
      for (var i = 0; i < 4; i++) {
        final piece = TrayPieceComponent(i, l)
          ..piece = PolyominoCatalog.byId('bar5_h');
        final size = l.traySlotSize;
        final img = await renderPixels(
          t,
          piece.render,
          size: size.x.ceil() + 4,
          background: const ui.Color(0x00000000),
        );
        var minX = img.width, maxX = -1;
        for (var y = 0; y < img.height; y++) {
          for (var x = 0; x < img.width; x++) {
            if (img.at(x, y).a > 0.5 &&
                img.at(x, y) != const ui.Color(0x00000000)) {
              minX = x < minX ? x : minX;
              maxX = x > maxX ? x : maxX;
            }
          }
        }
        expect(minX, greaterThanOrEqualTo(2), reason: 'slot $i left');
        expect(
          maxX,
          lessThanOrEqualTo(size.x.floor() - 2),
          reason: 'slot $i right',
        );
      }
    });
  });
}
