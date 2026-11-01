import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/game/cell_visual_renderer.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

final _rect = Rect.fromLTWH(0, 0, 100, 100);

Future<Pixels> _cell(WidgetTester t, GridCell cell, double time) =>
    renderPixels(t, (c) => CellVisualRenderer.paint(c, _rect, cell, time));

const _holo = GridCell(edition: CellEdition.holo);
const _poly = GridCell(edition: CellEdition.polychrome);
const _foil = GridCell(edition: CellEdition.foil);

double _peak(Pixels p, int cx, int cy, {int radius = 6}) {
  var best = 0.0;
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || y < 0 || x >= p.width || y >= p.height) continue;
      best = p.luminance(x, y) > best ? p.luminance(x, y) : best;
    }
  }
  return best;
}

void main() {
  group('animated looks', () {
    testWidgets('Holo shimmers: the whole square changes over time', (t) async {
      final a = await _cell(t, _holo, 0);
      final b = await _cell(t, _holo, 0.9);
      expect(a.differenceFrom(b), greaterThan(40));
      // Not just the middle: the corners move too.
      expect(a.at(12, 12), isNot(b.at(12, 12)));
      expect(a.at(87, 87), isNot(b.at(87, 87)));
    });

    testWidgets('Holo glows cyan AND magenta over a cycle', (t) async {
      var cyan = 0, magenta = 0;
      for (var i = 0; i < 12; i++) {
        final p = await _cell(t, _holo, i * 0.25);
        for (var y = 8; y < 92; y += 6) {
          for (var x = 8; x < 92; x += 6) {
            final hsv = HSVColor.fromColor(p.at(x, y));
            if (hsv.saturation < 0.15) continue;
            if (hsv.hue >= 170 && hsv.hue <= 205) cyan++;
            if (hsv.hue >= 275 && hsv.hue <= 335) magenta++;
          }
        }
      }
      expect(cyan, greaterThan(20));
      expect(magenta, greaterThan(20));
    });

    testWidgets('Polychrome cycles through many hues', (t) async {
      final a = await _cell(t, _poly, 0);
      final b = await _cell(t, _poly, 1.3);
      expect(a.differenceFrom(b), greaterThan(40));
      final hueBuckets = <int>{};
      for (var i = 0; i < 12; i++) {
        final p = await _cell(t, _poly, i * 0.3);
        for (var y = 10; y < 90; y += 8) {
          for (var x = 10; x < 90; x += 8) {
            final hsv = HSVColor.fromColor(p.at(x, y));
            if (hsv.saturation >= 0.15) hueBuckets.add(hsv.hue ~/ 45);
          }
        }
      }
      expect(hueBuckets.length, greaterThanOrEqualTo(5));
    });

    testWidgets('a diagonal shine band travels across the square', (t) async {
      // Foil is a silver wash plus the band, so the brightest column of the
      // band region moves as time advances.
      int brightestColumn(Pixels p) {
        var best = -1.0, at = 0;
        for (var x = 0; x < 100; x++) {
          var sum = 0.0;
          for (var y = 20; y < 80; y++) {
            sum += p.luminance(x, y);
          }
          if (sum > best) {
            best = sum;
            at = x;
          }
        }
        return at;
      }

      final early = brightestColumn(await _cell(t, _foil, 0.5));
      final late = brightestColumn(await _cell(t, _foil, 1.2));
      expect(late, greaterThan(early + 10));
    });

    testWidgets('Foil reads as silver even between shine sweeps', (t) async {
      final foil = await _cell(t, _foil, 1.2);
      final plain = await _cell(t, GridCell.plain, 1.2);
      expect(foil.saturation(20, 80), lessThan(plain.saturation(20, 80)));
      expect(foil.luminance(20, 80), greaterThan(plain.luminance(20, 80)));
    });

    testWidgets('Mult breathes; Lucky twinkles', (t) async {
      const mult = GridCell(enhancement: CellEnhancement.mult);
      const lucky = GridCell(enhancement: CellEnhancement.lucky);
      expect(
        (await _cell(t, mult, 0)).differenceFrom(await _cell(t, mult, 0.5)),
        greaterThan(5),
      );
      expect(
        (await _cell(t, lucky, 0)).differenceFrom(await _cell(t, lucky, 0.4)),
        greaterThan(1),
      );
    });

    testWidgets('Red Seal pulses', (t) async {
      const seal = GridCell(seal: CellSeal.red);
      expect(
        (await _cell(t, seal, 0)).differenceFrom(await _cell(t, seal, 0.5)),
        greaterThan(2),
      );
    });

    testWidgets('Steel, Gold, Glass and plain cells stay still', (t) async {
      for (final e in [
        CellEnhancement.none,
        CellEnhancement.steel,
        CellEnhancement.bonus,
        CellEnhancement.glass,
      ]) {
        final cell = GridCell(enhancement: e);
        expect(
          (await _cell(t, cell, 0)).differenceFrom(await _cell(t, cell, 2.2)),
          0,
          reason: e.name,
        );
      }
    });

    testWidgets('Steel keeps its look under a Holo edition too', (t) async {
      const both = GridCell(
        enhancement: CellEnhancement.steel,
        edition: CellEdition.holo,
      );
      final p = await _cell(t, both, 0.2);
      expect(_peak(p, 20, 20), greaterThan(0.7), reason: 'rivet still there');
      final q = await _cell(t, both, 1.1);
      expect(p.differenceFrom(q), greaterThan(30), reason: 'and it shimmers');
    });
  });
}
