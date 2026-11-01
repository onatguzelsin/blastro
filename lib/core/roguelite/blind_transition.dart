import '../grid/grid_matrix.dart';
import '../polyomino/block_bag.dart';
import '../polyomino/polyomino_shape.dart';
import 'ante_scaling.dart';

/// What the board and tray look like when the next blind begins.
class BlindEntry {
  const BlindEntry({
    required this.ante,
    required this.blind,
    required this.grid,
    required this.tray,
    required this.boardReset,
  });

  final int ante;
  final BlindType blind;
  final GridMatrix grid;

  /// A brand-new full 3-piece tray from the Block Bag.
  final List<Polyomino> tray;

  /// True when a defeated Boss wiped the board (a new Ante starts).
  final bool boardReset;
}

/// The rule for moving on after a blind is defeated.
///
/// * Board Persistence: every occupied cell stays on the 8x8 grid across
///   Small -> Big -> Boss; only defeating a Boss resets it.
/// * Full tray refresh: whatever is left in the tray is discarded and a new
///   full 3-piece tray is dealt from the [BlockBag].
abstract final class BlindTransition {
  /// The blind that follows [blind] in the same ante (Boss starts the next).
  static BlindType nextBlind(BlindType blind) => switch (blind) {
    BlindType.small => BlindType.big,
    BlindType.big => BlindType.boss,
    BlindType.boss => BlindType.small,
  };

  static int nextAnte(int ante, BlindType blind) => blind == BlindType.boss
      ? (ante + 1 > AnteScaling.lastEndlessAnte
            ? AnteScaling.lastEndlessAnte
            : ante + 1)
      : ante;

  /// Enters the blind after [blind] of [ante]. [grid] is not modified; the
  /// result holds either a copy of it or an empty board.
  static BlindEntry enterNext({
    required int ante,
    required BlindType blind,
    required GridMatrix grid,
    required BlockBag bag,
  }) {
    final bossDown = blind == BlindType.boss;
    return BlindEntry(
      ante: nextAnte(ante, blind),
      blind: nextBlind(blind),
      grid: bossDown ? GridMatrix() : grid.copy(),
      tray: bag.drawTray(),
      boardReset: bossDown,
    );
  }
}
