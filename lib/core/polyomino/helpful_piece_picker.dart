import 'dart:math';

import '../grid/fit_validator.dart';
import '../grid/grid_matrix.dart';
import 'polyomino_shape.dart';

/// Quick Play's gentle help for a crowded board. Picks which of the
/// [remaining] bag pieces to deal next, leaning toward pieces that actually
/// fit and toward small, easy ones. It is a weighted nudge, not a guarantee:
/// every piece keeps a chance.
abstract final class HelpfulPiecePicker {
  /// The board counts as crowded when MORE than this share of its cells are
  /// filled (so 45 of 64 cells, but not 44).
  static const double crowdedAbove = 0.70;

  /// A piece that fits somewhere is this many times likelier than one that
  /// fits nowhere (before the size weighting).
  static const double fitWeight = 3.0;
  static const double noFitWeight = 0.4;

  static bool isCrowded(GridMatrix board) =>
      board.occupiedCount / (GridMatrix.size * GridMatrix.size) > crowdedAbove;

  /// Easier (lower danger tier) pieces get a larger weight.
  static double sizeWeight(Polyomino p) => switch (p.dangerTier) {
    1 => 2.0,
    2 => 1.5,
    3 => 1.0,
    _ => 0.6,
  };

  static double weightOf(Polyomino p, GridMatrix board) =>
      (FitValidator.fitsAnywhere(board, p) ? fitWeight : noFitWeight) *
      sizeWeight(p);

  /// The index in [remaining] of the piece to deal. Consumes exactly one
  /// `nextDouble()` from [rng].
  static int pick(List<Polyomino> remaining, GridMatrix board, Random rng) {
    final weights = [for (final p in remaining) weightOf(p, board)];
    var roll = rng.nextDouble() * weights.fold<double>(0, (a, b) => a + b);
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return i;
    }
    return weights.length - 1;
  }
}
