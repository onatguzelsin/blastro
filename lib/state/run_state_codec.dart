import '../core/grid/grid_matrix.dart';
import '../core/polyomino/block_bag.dart';
import '../core/polyomino/block_color.dart';
import '../core/polyomino/polyomino_catalog.dart';
import '../core/polyomino/polyomino_shape.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/boss_blinds.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/run_mode.dart';
import '../core/roguelite/shop_generator.dart';
import '../core/roguelite/starter_decks.dart';
import '../core/scoring/clear_archetypes.dart';
import '../core/scoring/combo_window.dart';
import 'run_state.dart';

/// A run plus its bag, as stored on disk.
class SavedRun {
  const SavedRun(this.state, this.bag);

  final RunState state;
  final BlockBagSnapshot bag;
}

/// RunState <-> JSON. Jokers, cards and bosses are stored by id; ephemeral
/// replay data (`lastScore`, `preClearBoard`) is not saved.
abstract final class RunStateCodec {
  static const int version = 1;

  static Map<String, dynamic> encode(RunState s, BlockBagSnapshot bag) => {
    'v': version,
    'seed': s.seed,
    'deck': s.deckId,
    'mode': s.mode.name,
    'grid': s.grid.toJson(),
    'tray': [for (final p in s.tray) p == null ? null : _piece(p)],
    'combo': s.combo.toJson(),
    'jokers': [for (final j in s.jokers) j.id],
    'ante': s.ante,
    'blind': s.blind.name,
    'score': s.score,
    'trays': s.traysRemaining,
    'discards': s.discards,
    'gold': s.gold,
    'status': s.status.name,
    'placements': s.placements,
    'actions': s.actions,
    'endless': s.endless,
    'skipped': [for (final b in s.skipped) b.name],
    'consumables': s.consumables,
    'vouchers': s.vouchers,
    'levels': {for (final e in s.archetypeLevels.entries) e.key.name: e.value},
    'used': [for (final a in s.archetypesThisBlind) a.name],
    'shop': s.shop?.toJson(),
    'boss': s.boss?.id,
    'bag': bag.toJson(),
  };

  /// Throws on malformed data; callers fall back to a fresh run.
  static SavedRun decode(Map<String, dynamic> j) {
    if (j['v'] != version) throw const FormatException('save version');
    final state = RunState(
      seed: j['seed'] as int,
      deckId: (j['deck'] as String?) ?? StarterDeck.standardId,
      mode: RunMode.values.byName(
        (j['mode'] as String?) ?? RunMode.normal.name,
      ),
      grid: GridMatrix.fromJson(j['grid'] as List<dynamic>),
      tray: [
        for (final p in j['tray'] as List<dynamic>)
          p == null ? null : _pieceFrom(p as Map<String, dynamic>),
      ],
      combo: ComboWindow.fromJson(j['combo'] as Map<String, dynamic>),
      jokers: [
        for (final id in j['jokers'] as List<dynamic>)
          JokerRegistry.byId(id as String).joker,
      ],
      ante: j['ante'] as int,
      blind: BlindType.values.byName(j['blind'] as String),
      score: j['score'] as int,
      traysRemaining: j['trays'] as int,
      discards: j['discards'] as int,
      gold: j['gold'] as int,
      status: RunStatus.values.byName(j['status'] as String),
      placements: j['placements'] as int,
      actions: j['actions'] as int,
      endless: (j['endless'] as bool?) ?? false,
      skipped: [
        for (final n in (j['skipped'] as List<dynamic>?) ?? const [])
          BlindType.values.byName(n as String),
      ],
      consumables: List<String>.from(j['consumables'] as List),
      vouchers: List<String>.from((j['vouchers'] as List?) ?? const []),
      archetypeLevels: {
        for (final e in (j['levels'] as Map<String, dynamic>).entries)
          ClearArchetype.values.byName(e.key): e.value as int,
      },
      archetypesThisBlind: [
        for (final n in j['used'] as List<dynamic>)
          ClearArchetype.values.byName(n as String),
      ],
      shop: j['shop'] == null
          ? null
          : ShopState.fromJson(j['shop'] as Map<String, dynamic>),
      boss: j['boss'] == null ? null : BossRegistry.byId(j['boss'] as String),
    );
    return SavedRun(
      state,
      BlockBagSnapshot.fromJson(j['bag'] as Map<String, dynamic>),
    );
  }

  static Map<String, dynamic> _piece(Polyomino p) => {
    'id': p.id,
    if (p.color != null) 'color': p.color!.name,
    'cells': [
      for (final c in p.cells) [c.row, c.col],
    ],
  };

  static Polyomino _pieceFrom(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return Polyomino(
      id,
      [
        for (final c in j['cells'] as List<dynamic>)
          CellOffset((c as List)[0] as int, c[1] as int),
      ],
      dangerTier: PolyominoCatalog.byId(id).dangerTier,
      color: j['color'] == null
          ? null
          : BlockColor.values.byName(j['color'] as String),
    );
  }
}
