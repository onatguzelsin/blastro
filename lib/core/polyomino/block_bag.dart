import 'dart:math';

import '../grid/grid_matrix.dart';
import 'block_color.dart';
import 'helpful_piece_picker.dart';
import 'polyomino_catalog.dart';
import 'polyomino_shape.dart';

/// Serializable bag state. The RNGs themselves are restored by replaying
/// [shuffles] shuffles and [colorDraws] color draws from [seed].
class BlockBagSnapshot {
  const BlockBagSnapshot({
    required this.seed,
    required this.shuffles,
    required this.remainingIds,
    this.colorDraws = 0,
    this.assistDraws = 0,
  });

  factory BlockBagSnapshot.fromJson(Map<String, dynamic> json) =>
      BlockBagSnapshot(
        seed: json['seed'] as int,
        shuffles: json['shuffles'] as int,
        remainingIds: List<String>.from(json['remaining'] as List),
        colorDraws: (json['colors'] as int?) ?? 0,
        assistDraws: (json['assist'] as int?) ?? 0,
      );

  final int seed;
  final int shuffles;
  final List<String> remainingIds;
  final int colorDraws;

  /// How many times the helpful-piece picker was used (Quick Play only).
  final int assistDraws;

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'shuffles': shuffles,
    'remaining': remainingIds,
    'colors': colorDraws,
    'assist': assistDraws,
  };
}

/// Seeded deck of polyominoes. Pieces are drawn without replacement; when the
/// bag runs dry it is refilled with the whole [pool] and reshuffled.
///
/// A starter deck chooses the pool (it may hold duplicates) and the palette
/// of colors pieces are dealt in. Colors come from their own random stream,
/// so the palette never changes the order of shapes for a given seed.
class BlockBag {
  BlockBag(
    this.seed, {
    List<Polyomino>? catalog,
    List<BlockColor>? palette,
    this.traySize = defaultTraySize,
    this.adaptive = false,
  }) : _catalog = catalog ?? PolyominoCatalog.all,
       _palette = palette ?? BlockColor.values,
       _rng = Random(seed),
       _colorRng = Random(seed ^ _colorSalt),
       _assistRng = Random(seed ^ _assistSalt) {
    assert(_palette.isNotEmpty, 'A bag needs at least one color');
    _refill();
  }

  BlockBag._restored(
    this.seed,
    this._catalog,
    this._palette,
    this._rng,
    this._colorRng,
    this._assistRng,
    this._shuffles,
    this._colorDraws,
    this._assistDraws,
    this.traySize,
    this.adaptive,
  );

  factory BlockBag.restore(
    BlockBagSnapshot snapshot, {
    List<Polyomino>? catalog,
    List<BlockColor>? palette,
    int traySize = defaultTraySize,
    bool adaptive = false,
  }) {
    final pieces = catalog ?? PolyominoCatalog.all;
    final colors = palette ?? BlockColor.values;
    final rng = Random(snapshot.seed);
    // Replay RNG consumption: shuffle consumption depends only on length.
    for (var i = 0; i < snapshot.shuffles; i++) {
      List<Polyomino>.of(pieces).shuffle(rng);
    }
    final colorRng = Random(snapshot.seed ^ _colorSalt);
    for (var i = 0; i < snapshot.colorDraws; i++) {
      colorRng.nextInt(colors.length);
    }
    final assistRng = Random(snapshot.seed ^ _assistSalt);
    for (var i = 0; i < snapshot.assistDraws; i++) {
      assistRng.nextDouble();
    }
    final bag = BlockBag._restored(
      snapshot.seed,
      pieces,
      colors,
      rng,
      colorRng,
      assistRng,
      snapshot.shuffles,
      snapshot.colorDraws,
      snapshot.assistDraws,
      traySize,
      adaptive,
    );
    final byId = {for (final p in pieces) p.id: p};
    bag._remaining.addAll(snapshot.remainingIds.map((id) => byId[id]!));
    return bag;
  }

  /// Normal runs deal 3 pieces per tray; Quick Play deals 4.
  static const int defaultTraySize = 3;
  static const int _colorSalt = 0x5bd1e995;
  static const int _assistSalt = 0x2c1b3c6d;

  final int seed;

  /// Pieces dealt per tray.
  final int traySize;

  /// Quick Play: lean toward helpful pieces when the board is crowded.
  final bool adaptive;
  final List<Polyomino> _catalog;
  final List<BlockColor> _palette;
  final Random _rng;
  final Random _colorRng;
  final Random _assistRng;
  final List<Polyomino> _remaining = [];
  int _shuffles = 0;
  int _colorDraws = 0;
  int _assistDraws = 0;

  /// Pieces still in the bag (uncolored: a color is chosen as a piece is
  /// dealt), in draw order from the END of the list.
  List<Polyomino> get remaining => List.unmodifiable(_remaining);

  /// Every piece the bag is refilled with.
  List<Polyomino> get pool => List.unmodifiable(_catalog);

  List<BlockColor> get palette => List.unmodifiable(_palette);

  /// Deals the next piece. Passing the [board] lets an [adaptive] bag help
  /// when it is crowded; normal bags ignore it.
  Polyomino draw({GridMatrix? board}) {
    if (_remaining.isEmpty) _refill();
    final shape = _takeNext(board);
    _colorDraws++;
    return shape.withColor(_palette[_colorRng.nextInt(_palette.length)]);
  }

  /// Deals a fresh tray of [traySize] pieces.
  List<Polyomino> drawTray({GridMatrix? board}) =>
      List.generate(traySize, (_) => draw(board: board));

  Polyomino _takeNext(GridMatrix? board) {
    if (!adaptive || board == null || !HelpfulPiecePicker.isCrowded(board)) {
      return _remaining.removeLast();
    }
    _assistDraws++;
    final i = HelpfulPiecePicker.pick(_remaining, board, _assistRng);
    return _remaining.removeAt(i);
  }

  void _refill() {
    _remaining
      ..clear()
      ..addAll(_catalog)
      ..shuffle(_rng);
    _shuffles++;
  }

  BlockBagSnapshot snapshot() => BlockBagSnapshot(
    seed: seed,
    shuffles: _shuffles,
    remainingIds: _remaining.map((p) => p.id).toList(),
    colorDraws: _colorDraws,
    assistDraws: _assistDraws,
  );
}
