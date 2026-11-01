import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/game/board_component.dart';
import 'package:blastro/game/game_layout.dart';
import 'package:blastro/game/tray_piece_component.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';

import 'pixel_test_support.dart';

const _holo = GridCell(edition: CellEdition.holo);
const _steel = GridCell(enhancement: CellEnhancement.steel);

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
  group('the same look on the board and in the tray', () {
    final layout = GameLayout.compute(Vector2(400, 800));

    testWidgets('BoardComponent draws a steel cell with rivets', (t) async {
      final board = BoardComponent(layout, GridMatrix()..setCell(0, 0, _steel));
      final p = await renderPixels(t, board.render, size: 400);
      final c = layout.cell;
      // Cell rect is (1, 1, c-2, c-2); rivets sit 20% in from each corner.
      final inset = (c - 2) * 0.2;
      for (final (x, y) in [
        (1 + inset, 1 + inset),
        (c - 1 - inset, 1 + inset),
        (1 + inset, c - 1 - inset),
        (c - 1 - inset, c - 1 - inset),
      ]) {
        expect(_peak(p, x.round(), y.round(), radius: 4), greaterThan(0.8));
      }
      // The neighbouring empty tile is just the dark empty colour.
      expect(p.luminance((c * 1.5).round(), (c / 2).round()), lessThan(0.05));
    });

    testWidgets('BoardComponent animates a Holo cell via its time', (t) async {
      final board = BoardComponent(layout, GridMatrix()..setCell(2, 3, _holo));
      final a = await renderPixels(t, board.render, size: 400);
      board.time = 0.9;
      final b = await renderPixels(t, board.render, size: 400);
      expect(a.differenceFrom(b, step: 2), greaterThan(20));
    });

    testWidgets('TrayPieceComponent draws its piece through the renderer', (
      t,
    ) async {
      final piece = TrayPieceComponent(0, layout)
        ..piece = PolyominoCatalog.byId('dot')
        ..cell = _steel;
      final p = await renderPixels(t, piece.render, size: 200);
      final cs = layout.cell * GameLayout.trayScale;
      final left = piece.size.x / 2 - cs / 2 + 1;
      final top = piece.size.y / 2 - cs / 2 + 1;
      final inset = (cs - 2) * 0.2;
      expect(
        _peak(p, (left + inset).round(), (top + inset).round(), radius: 3),
        greaterThan(0.62),
      );
      expect(
        _peak(
          p,
          (left + cs - 2 - inset).round(),
          (top + cs - 2 - inset).round(),
          radius: 3,
        ),
        greaterThan(0.62),
      );
    });

    testWidgets('a plain tray piece has no rivets', (t) async {
      final piece = TrayPieceComponent(0, layout)
        ..piece = PolyominoCatalog.byId('dot');
      final p = await renderPixels(t, piece.render, size: 200);
      final cs = layout.cell * GameLayout.trayScale;
      final left = piece.size.x / 2 - cs / 2 + 1;
      final top = piece.size.y / 2 - cs / 2 + 1;
      expect(
        _peak(
          p,
          (left + (cs - 2) * 0.2).round(),
          (top + (cs - 2) * 0.2).round(),
          radius: 3,
        ),
        lessThan(0.55),
      );
    });

    testWidgets('a multi-cell tray piece paints every cell', (t) async {
      final piece = TrayPieceComponent(0, layout)
        ..piece = PolyominoCatalog.byId('plus')
        ..cell = _steel;
      final p = await renderPixels(t, piece.render, size: 200);
      final cs = layout.cell * GameLayout.trayScale;
      final ox = piece.size.x / 2 - 1.5 * cs;
      final oy = piece.size.y / 2 - 1.5 * cs;
      var rivets = 0;
      for (final (r, c) in [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]) {
        final inset = (cs - 2) * 0.2;
        if (_peak(
              p,
              (ox + c * cs + 1 + inset).round(),
              (oy + r * cs + 1 + inset).round(),
              radius: 3,
            ) >
            0.62) {
          rivets++;
        }
      }
      expect(rivets, 5);
    });
  });
}
