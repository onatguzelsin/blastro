import 'polyomino_shape.dart';

/// The 24 base Block Blast shapes. Block Blast pieces are fixed-orientation,
/// so each orientation that appears in the bag is its own catalog entry.
/// `Polyomino.variants` exposes rotations/mirrors (S is the mirror of Z) for
/// when rotation is unlocked.
abstract final class PolyominoCatalog {
  static final List<Polyomino> all = List.unmodifiable([
    // 1x1 dot
    Polyomino.fromAscii('dot', ['X']),
    // Horizontal bars 2..5
    Polyomino.fromAscii('bar2_h', ['XX']),
    Polyomino.fromAscii('bar3_h', ['XXX'], dangerTier: 2),
    Polyomino.fromAscii('bar4_h', ['XXXX'], dangerTier: 3),
    Polyomino.fromAscii('bar5_h', ['XXXXX'], dangerTier: 4),
    // Vertical bars 2..5
    Polyomino.fromAscii('bar2_v', ['X', 'X']),
    Polyomino.fromAscii('bar3_v', ['X', 'X', 'X'], dangerTier: 2),
    Polyomino.fromAscii('bar4_v', ['X', 'X', 'X', 'X'], dangerTier: 3),
    Polyomino.fromAscii('bar5_v', ['X', 'X', 'X', 'X', 'X'], dangerTier: 4),
    // Solid squares / rectangles
    Polyomino.fromAscii('rect_2x2', ['XX', 'XX']),
    Polyomino.fromAscii('rect_2x3', ['XXX', 'XXX'], dangerTier: 3),
    Polyomino.fromAscii('rect_3x2', ['XX', 'XX', 'XX'], dangerTier: 3),
    Polyomino.fromAscii('rect_3x3', ['XXX', 'XXX', 'XXX'], dangerTier: 4),
    // Small L-corners (3 cells), four orientations
    Polyomino.fromAscii('l_small_0', ['X.', 'XX']),
    Polyomino.fromAscii('l_small_1', ['.X', 'XX']),
    Polyomino.fromAscii('l_small_2', ['XX', 'X.']),
    Polyomino.fromAscii('l_small_3', ['XX', '.X']),
    // Big L-corners (5 cells), four orientations
    Polyomino.fromAscii('l_big_0', ['X..', 'X..', 'XXX'], dangerTier: 4),
    Polyomino.fromAscii('l_big_1', ['..X', '..X', 'XXX'], dangerTier: 4),
    Polyomino.fromAscii('l_big_2', ['XXX', 'X..', 'X..'], dangerTier: 4),
    Polyomino.fromAscii('l_big_3', ['XXX', '..X', '..X'], dangerTier: 4),
    // Plus, T and Z (S = mirrored Z variant)
    Polyomino.fromAscii('plus', ['.X.', 'XXX', '.X.'], dangerTier: 4),
    Polyomino.fromAscii('tee', ['XXX', '.X.'], dangerTier: 2),
    Polyomino.fromAscii('zig', ['XX.', '.XX'], dangerTier: 2),
  ]);

  static final Map<String, Polyomino> _byId = {for (final p in all) p.id: p};

  static Polyomino byId(String id) {
    final shape = _byId[id];
    if (shape == null) throw ArgumentError('Unknown polyomino id: $id');
    return shape;
  }
}
