import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/polyomino/block_color.dart';
import 'package:blastro/game/cell_visual_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

final _rect = Rect.fromLTWH(0, 0, 100, 100);

Future<Pixels> _cell(WidgetTester t, GridCell cell) =>
    renderPixels(t, (c) => CellVisualRenderer.paint(c, _rect, cell, 0));

double _hue(Pixels p, int x, int y) => HSVColor.fromColor(p.at(x, y)).hue;

bool _near(double hue, double target, [double tol = 25]) {
  final d = (hue - target).abs();
  return d < tol || 360 - d < tol;
}

void main() {
  group('plain blocks wear their color', () {
    testWidgets('red, blue, green and yellow are four distinct looks', (
      t,
    ) async {
      final looks = {
        for (final c in BlockColor.values)
          c: await _cell(t, GridCell(color: c)),
      };
      final centers = {
        for (final e in looks.entries) e.key: e.value.at(50, 60),
      };
      expect(centers.values.toSet().length, 4);
      expect(_near(_hue(looks[BlockColor.red]!, 50, 60), 3), isTrue);
      expect(_near(_hue(looks[BlockColor.green]!, 50, 60), 132, 30), isTrue);
      expect(_near(_hue(looks[BlockColor.yellow]!, 50, 60), 46, 20), isTrue);
      expect(_near(_hue(looks[BlockColor.blue]!, 50, 60), 222, 25), isTrue);
    });

    testWidgets('an uncolored cell looks Blue, exactly as blocks always did', (
      t,
    ) async {
      final none = await _cell(t, GridCell.plain);
      final blue = await _cell(t, const GridCell(color: BlockColor.blue));
      expect(none.differenceFrom(blue), 0);
    });

    testWidgets('every color fills the whole square', (t) async {
      for (final c in BlockColor.values) {
        final p = await _cell(t, GridCell(color: c));
        for (final (x, y) in [(12, 12), (87, 12), (12, 87), (87, 87)]) {
          expect(p.at(x, y), isNot(const Color(0xFF1E2433)), reason: '$c');
        }
      }
    });
  });

  group('enhanced cells keep their look and show the color on an edge', () {
    const steel = CellEnhancement.steel;

    testWidgets('a colored Steel cell still has its rivets and grey metal', (
      t,
    ) async {
      final p = await _cell(
        t,
        const GridCell(enhancement: steel, color: BlockColor.red),
      );
      expect(p.saturation(50, 30), lessThan(0.25), reason: 'still metal');
      var best = 0.0;
      for (var y = 14; y <= 26; y++) {
        for (var x = 14; x <= 26; x++) {
          best = p.luminance(x, y) > best ? p.luminance(x, y) : best;
        }
      }
      expect(best, greaterThan(0.8), reason: 'rivet');
    });

    testWidgets('the color edge is on the bottom, only when the cell has one', (
      t,
    ) async {
      final red = await _cell(
        t,
        const GridCell(enhancement: steel, color: BlockColor.red),
      );
      final none = await _cell(t, const GridCell(enhancement: steel));
      expect(_near(_hue(red, 50, 94), 3, 20), isTrue);
      expect(red.saturation(50, 94), greaterThan(0.5));
      expect(none.saturation(50, 94), lessThan(0.3));
      // The rest of the cell is identical.
      expect(red.at(50, 40), none.at(50, 40));
    });

    testWidgets('Bonus, Mult and Lucky keep their own colors', (t) async {
      for (final e in [
        CellEnhancement.bonus,
        CellEnhancement.mult,
        CellEnhancement.lucky,
      ]) {
        final plain = await _cell(t, GridCell(enhancement: e));
        final coloured = await _cell(
          t,
          GridCell(enhancement: e, color: BlockColor.blue),
        );
        expect(coloured.at(50, 40), plain.at(50, 40), reason: e.name);
      }
    });
  });
}
