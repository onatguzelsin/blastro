import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/game/cell_visual_renderer.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

const _bg = Color(0xFF1E2433);
final _rect = Rect.fromLTWH(0, 0, 100, 100);

Future<Pixels> _cell(
  WidgetTester t,
  GridCell cell, {
  double time = 0,
  Color background = _bg,
}) => renderPixels(
  t,
  (c) => CellVisualRenderer.paint(c, _rect, cell, time),
  background: background,
);

const _steel = GridCell(enhancement: CellEnhancement.steel);

/// The brightest pixel in a small window around ([cx], [cy]).
double _peak(Pixels p, int cx, int cy, {int radius = 6}) {
  var best = 0.0;
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      final l = p.luminance(x, y);
      if (l > best) best = l;
    }
  }
  return best;
}

void main() {
  group('Steel', () {
    testWidgets('has a rivet at each of the 4 corners, plain cells do not', (
      t,
    ) async {
      final steel = await _cell(t, _steel);
      final plain = await _cell(t, GridCell.plain);
      for (final (x, y) in [(20, 20), (80, 20), (20, 80), (80, 80)]) {
        expect(_peak(steel, x, y), greaterThan(0.8), reason: 'rivet $x,$y');
        expect(_peak(plain, x, y), lessThan(0.55), reason: 'plain $x,$y');
      }
    });

    testWidgets('is grey metal, not coloured like a plain block', (t) async {
      final steel = await _cell(t, _steel);
      final plain = await _cell(t, GridCell.plain);
      expect(steel.saturation(50, 30), lessThan(0.25));
      expect(plain.saturation(50, 30), greaterThan(0.4));
    });

    testWidgets('has a vertical metallic gradient', (t) async {
      final steel = await _cell(t, _steel);
      expect(
        (steel.luminance(60, 14) - steel.luminance(60, 70)).abs(),
        greaterThan(0.08),
      );
    });

    testWidgets('has a bevel: bright top edge, dark bottom edge', (t) async {
      final steel = await _cell(t, _steel);
      expect(
        steel.luminance(50, 2),
        greaterThan(steel.luminance(50, 97) + 0.3),
      );
      expect(
        steel.luminance(2, 50),
        greaterThan(steel.luminance(97, 50) + 0.2),
      );
    });

    testWidgets('has brushed grain: fine lines, not a flat fill', (t) async {
      final steel = await _cell(t, _steel);
      var changes = 0;
      for (var y = 30; y < 70; y++) {
        if ((steel.luminance(40, y) - steel.luminance(40, y + 1)).abs() >
            0.004) {
          changes++;
        }
      }
      expect(changes, greaterThan(15));
    });

    testWidgets('does not animate', (t) async {
      final a = await _cell(t, _steel);
      final b = await _cell(t, _steel, time: 3.7);
      expect(a.differenceFrom(b), 0);
    });
  });

  group('every special cell fills the whole square', () {
    final looks = <String, GridCell>{
      'plain': GridCell.plain,
      'bonus': const GridCell(enhancement: CellEnhancement.bonus),
      'mult': const GridCell(enhancement: CellEnhancement.mult),
      'glass': const GridCell(enhancement: CellEnhancement.glass),
      'lucky': const GridCell(enhancement: CellEnhancement.lucky),
      'steel': _steel,
      'foil': const GridCell(edition: CellEdition.foil),
      'holo': const GridCell(edition: CellEdition.holo),
      'polychrome': const GridCell(edition: CellEdition.polychrome),
      'red seal': const GridCell(seal: CellSeal.red),
    };

    for (final e in looks.entries) {
      testWidgets(e.key, (t) async {
        final p = await _cell(t, e.value, time: 0.3);
        for (final (x, y) in [
          (12, 12),
          (87, 12),
          (12, 87),
          (87, 87),
          (50, 50),
        ]) {
          expect(p.at(x, y), isNot(_bg), reason: '${e.key} at $x,$y');
        }
      });
    }

    testWidgets('and the corners are rounded (outside is untouched)', (
      t,
    ) async {
      final p = await _cell(t, _steel);
      expect(p.at(0, 0), _bg);
      expect(p.at(99, 99), _bg);
    });
  });

  group('Gold, Glass, Seal', () {
    testWidgets('Bonus is metallic gold with a darker gold frame', (t) async {
      final gold = await _cell(
        t,
        const GridCell(enhancement: CellEnhancement.bonus),
      );
      final c = gold.at(50, 70);
      expect(c.r, greaterThan(0.85));
      expect(c.g, inInclusiveRange(0.55, 0.95));
      expect(c.b, lessThan(0.5));
      expect(gold.luminance(1, 50), lessThan(gold.luminance(50, 70)));
    });

    testWidgets('Glass is translucent: the tile behind shows through', (
      t,
    ) async {
      const glass = GridCell(enhancement: CellEnhancement.glass);
      final onDark = await _cell(t, glass);
      final onWhite = await _cell(
        t,
        glass,
        background: const Color(0xFFFFFFFF),
      );
      expect(onDark.at(50, 80), isNot(onWhite.at(50, 80)));
      expect(onDark.luminance(50, 80), lessThan(onWhite.luminance(50, 80)));
    });

    testWidgets('Glass has an ice-blue frame and a diagonal reflection', (
      t,
    ) async {
      final p = await _cell(
        t,
        const GridCell(enhancement: CellEnhancement.glass),
      );
      final frame = p.at(50, 1);
      expect(frame.b, greaterThan(frame.r));
      // The wide reflection runs from the bottom-left up to the top-right.
      var bright = 0;
      for (var y = 10; y <= 90; y += 10) {
        final x = (18 + 8 + 0.55 * (100 - y)).round();
        if (p.luminance(x, y) > p.luminance(x - 22, y) + 0.12) bright++;
      }
      expect(bright, greaterThan(5));
    });

    testWidgets('Red Seal is a red frame around all four sides', (t) async {
      final p = await _cell(t, const GridCell(seal: CellSeal.red), time: 0.3);
      for (final (x, y) in [(50, 1), (50, 98), (1, 50), (98, 50)]) {
        final c = p.at(x, y);
        expect(c.r, greaterThan(0.8), reason: 'side $x,$y');
        expect(c.g, lessThan(0.35), reason: 'side $x,$y');
      }
    });
  });
}
