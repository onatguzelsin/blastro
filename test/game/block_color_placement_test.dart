import 'dart:ui' as ui;

import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/game/board_component.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/game/tray_piece_component.dart';
import 'package:blastro/ui/deck_emblem.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

double _hue(Pixels p, int x, int y) => HSVColor.fromColor(p.at(x, y)).hue;

bool _near(double hue, double target, [double tol = 25]) {
  final d = (hue - target).abs();
  return d < tol || 360 - d < tol;
}

void main() {
  group('on the board and in the tray', () {
    final layout = GameLayout.compute(Vector2(400, 800));

    testWidgets('the board draws a red piece red and a blue piece blue', (
      t,
    ) async {
      final grid = GridMatrix()
        ..place(PolyominoCatalog.byId('dot').withColor(BlockColor.red), 0, 0)
        ..place(PolyominoCatalog.byId('dot').withColor(BlockColor.blue), 0, 1);
      final board = BoardComponent(layout, grid);
      final p = await renderPixels(t, board.render, size: 400);
      final c = layout.cell.round();
      expect(_near(_hue(p, c ~/ 2, c ~/ 2 + 6), 3), isTrue);
      expect(_near(_hue(p, c + c ~/ 2, c ~/ 2 + 6), 222, 25), isTrue);
    });

    testWidgets('a tray piece is drawn in the color it was dealt', (t) async {
      for (final (color, hue, tol) in [
        (BlockColor.red, 3.0, 25.0),
        (BlockColor.green, 132.0, 30.0),
        (BlockColor.yellow, 46.0, 20.0),
      ]) {
        final piece = TrayPieceComponent(0, layout)
          ..piece = PolyominoCatalog.byId('dot').withColor(color);
        final p = await renderPixels(t, piece.render, size: 200);
        final cx = (piece.size.x / 2).round();
        final cy = (piece.size.y / 2).round() + 3;
        expect(_near(_hue(p, cx, cy), hue, tol), isTrue, reason: '$color');
      }
    });
  });

  group('deck emblems', () {
    Future<Pixels> emblem(WidgetTester t, String id) async {
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF14171F),
                child: DeckEmblem(deckId: id, size: 100),
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await t.runAsync(() => boundary.toImage());
      final data = await t.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      return Pixels(image!.width, image.height, data!);
    }

    testWidgets('each of the five draws something, and they all differ', (
      t,
    ) async {
      final images = <String, Pixels>{};
      for (final d in StarterDecks.all) {
        images[d.id] = await emblem(t, d.id);
        var lit = 0;
        final p = images[d.id]!;
        for (var y = 0; y < p.height; y += 3) {
          for (var x = 0; x < p.width; x += 3) {
            if (p.at(x, y) != const Color(0xFF14171F)) lit++;
          }
        }
        expect(lit, greaterThan(60), reason: d.name);
      }
      final ids = images.keys.toList();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          expect(
            images[ids[i]]!.differenceFrom(images[ids[j]]!),
            greaterThan(30),
            reason: '${ids[i]} vs ${ids[j]}',
          );
        }
      }
    });

    testWidgets('the Chromatic emblem is red AND blue and nothing else', (
      t,
    ) async {
      final p = await emblem(t, 'deck_chromatic_flush');
      var red = 0, blue = 0, green = 0, yellow = 0;
      for (var y = 0; y < p.height; y += 2) {
        for (var x = 0; x < p.width; x += 2) {
          final hsv = HSVColor.fromColor(p.at(x, y));
          if (hsv.saturation < 0.4 || hsv.value < 0.4) continue;
          if (_near(hsv.hue, 3, 25)) red++;
          if (_near(hsv.hue, 222, 25)) blue++;
          if (_near(hsv.hue, 132, 30)) green++;
          if (_near(hsv.hue, 46, 20)) yellow++;
        }
      }
      expect(red, greaterThan(100));
      expect(blue, greaterThan(100));
      expect(green + yellow, 0);
    });

    testWidgets('the Standard emblem shows all four colors', (t) async {
      final p = await emblem(t, 'deck_standard');
      final seen = <String>{};
      for (var y = 0; y < p.height; y += 2) {
        for (var x = 0; x < p.width; x += 2) {
          final hsv = HSVColor.fromColor(p.at(x, y));
          if (hsv.saturation < 0.4 || hsv.value < 0.4) continue;
          if (_near(hsv.hue, 3, 25)) seen.add('red');
          if (_near(hsv.hue, 222, 25)) seen.add('blue');
          if (_near(hsv.hue, 132, 30)) seen.add('green');
          if (_near(hsv.hue, 46, 20)) seen.add('yellow');
        }
      }
      expect(seen, {'red', 'blue', 'green', 'yellow'});
    });
  });
}
