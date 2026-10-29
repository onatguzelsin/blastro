import 'dart:math';

import 'polyomino_catalog.dart';
import 'polyomino_shape.dart';

/// Serializable bag state. The RNG itself is restored by replaying
/// [shuffles] shuffles from [seed].
class BlockBagSnapshot {
  const BlockBagSnapshot({
    required this.seed,
    required this.shuffles,
    required this.remainingIds,
  });

  factory BlockBagSnapshot.fromJson(Map<String, dynamic> json) =>
      BlockBagSnapshot(
        seed: json['seed'] as int,
        shuffles: json['shuffles'] as int,
        remainingIds: List<String>.from(json['remaining'] as List),
      );

  final int seed;
  final int shuffles;
  final List<String> remainingIds;

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'shuffles': shuffles,
    'remaining': remainingIds,
  };
}

/// Seeded deck of polyominoes. Pieces are drawn without replacement; when the
/// bag runs dry it is refilled with all catalog shapes and reshuffled.
class BlockBag {
  BlockBag(this.seed, {List<Polyomino>? catalog})
    : _catalog = catalog ?? PolyominoCatalog.all,
      _rng = Random(seed) {
    _refill();
  }

  BlockBag._restored(this.seed, this._catalog, this._rng, this._shuffles);

  factory BlockBag.restore(
    BlockBagSnapshot snapshot, {
    List<Polyomino>? catalog,
  }) {
    final pieces = catalog ?? PolyominoCatalog.all;
    final rng = Random(snapshot.seed);
    // Replay RNG consumption: shuffle consumption depends only on length.
    for (var i = 0; i < snapshot.shuffles; i++) {
      List<Polyomino>.of(pieces).shuffle(rng);
    }
    final bag = BlockBag._restored(
      snapshot.seed,
      pieces,
      rng,
      snapshot.shuffles,
    );
    final byId = {for (final p in pieces) p.id: p};
    bag._remaining.addAll(snapshot.remainingIds.map((id) => byId[id]!));
    return bag;
  }

  static const int traySize = 3;

  final int seed;
  final List<Polyomino> _catalog;
  final Random _rng;
  final List<Polyomino> _remaining = [];
  int _shuffles = 0;

  /// Pieces still in the bag, in draw order from the END of the list.
  List<Polyomino> get remaining => List.unmodifiable(_remaining);

  Polyomino draw() {
    if (_remaining.isEmpty) _refill();
    return _remaining.removeLast();
  }

  /// Deals a fresh 3-piece tray.
  List<Polyomino> drawTray() => List.generate(traySize, (_) => draw());

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
  );
}
