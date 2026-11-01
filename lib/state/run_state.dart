import '../core/grid/grid_matrix.dart';
import '../core/polyomino/polyomino_shape.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/boss_blinds.dart';
import '../core/roguelite/joker_effects.dart';
import '../core/roguelite/run_modifiers.dart';
import '../core/roguelite/shop_generator.dart';
import '../core/roguelite/vouchers.dart';
import '../core/scoring/clear_archetypes.dart';
import '../core/scoring/combo_window.dart';
import '../core/scoring/scoring_pipeline.dart';

/// blindSelect (pick a blind) -> playing -> blindCleared (cash out) ->
/// shopping -> blindSelect (next blind). Beating the Ante 8 Finisher pauses
/// at [victory] first.
enum RunStatus { blindSelect, playing, blindCleared, shopping, victory, lost }

/// Immutable snapshot of a run. [grid] must never be mutated in place; the
/// notifier always swaps in a copy.
class RunState {
  const RunState({
    required this.seed,
    required this.grid,
    required this.tray,
    required this.combo,
    required this.jokers,
    required this.ante,
    required this.blind,
    required this.score,
    required this.traysRemaining,
    required this.discards,
    required this.gold,
    this.status = RunStatus.playing,
    this.placements = 0,
    this.actions = 0,
    this.endless = false,
    this.skipped = const [],
    this.consumables = const [],
    this.vouchers = const [],
    this.archetypeLevels = const {},
    this.archetypesThisBlind = const [],
    this.shop,
    this.boss,
    this.scoreSerial = 0,
    this.lastScore,
    this.preClearBoard,
  });

  static const int maxJokers = ShopGenerator.maxJokers;
  static const int traysPerBlind = 5;
  static const int discardsPerBlind = 3;
  static const int startingGold = 4;

  final int seed;
  final GridMatrix grid;

  /// Three tray slots; a slot is null once its piece has been placed.
  final List<Polyomino?> tray;
  final ComboWindow combo;
  final List<Joker> jokers;
  final int ante;
  final BlindType blind;
  final int score;

  /// Trays left including the one currently in play.
  final int traysRemaining;
  final int discards;
  final int gold;
  final RunStatus status;
  final int placements;

  /// Bumped on every shop/consumable action; seeds their randomness.
  final int actions;

  /// The player beat the Ante 8 Finisher and chose to keep going (Antes 9+).
  final bool endless;

  /// Blinds of this ante that were skipped instead of played.
  final List<BlindType> skipped;

  /// Held consumable ids (max 2).
  final List<String> consumables;

  /// Owned voucher ids: permanent upgrades, one purchase each.
  final List<String> vouchers;
  final Map<ClearArchetype, int> archetypeLevels;

  /// Archetypes that scored this blind, in order (The Eye / The Mouth).
  final List<ClearArchetype> archetypesThisBlind;
  final ShopState? shop;

  /// Active Boss Blind; null unless [blind] is the Boss.
  final BossBlind? boss;

  /// Bumped on every placement so the game layer can replay [lastScore].
  final int scoreSerial;
  final ScoreResult? lastScore;

  /// Board after the last placement but before its lines were removed, so
  /// the score replay can show the cells being scored.
  final GridMatrix? preClearBoard;

  /// Jokers plus owned vouchers.
  RunModifiers get modifiers => RunModifiers.fromRun(jokers, [
    for (final id in vouchers) VoucherRegistry.byId(id).modifiers,
  ]);

  int get target => AnteScaling.targetFor(
    ante,
    blind,
    bossMultiplier: boss?.targetMultiplier,
  );

  List<Polyomino> get unplaced => tray.whereType<Polyomino>().toList();

  RunState copyWith({
    GridMatrix? grid,
    List<Polyomino?>? tray,
    ComboWindow? combo,
    List<Joker>? jokers,
    int? ante,
    BlindType? blind,
    int? score,
    int? traysRemaining,
    int? discards,
    int? gold,
    RunStatus? status,
    int? placements,
    int? actions,
    bool? endless,
    List<BlindType>? skipped,
    List<String>? consumables,
    List<String>? vouchers,
    Map<ClearArchetype, int>? archetypeLevels,
    List<ClearArchetype>? archetypesThisBlind,
    ShopState? shop,
    bool clearShop = false,
    BossBlind? boss,
    bool clearBoss = false,
    int? scoreSerial,
    ScoreResult? lastScore,
    GridMatrix? preClearBoard,
  }) => RunState(
    seed: seed,
    grid: grid ?? this.grid,
    tray: tray ?? this.tray,
    combo: combo ?? this.combo,
    jokers: jokers ?? this.jokers,
    ante: ante ?? this.ante,
    blind: blind ?? this.blind,
    score: score ?? this.score,
    traysRemaining: traysRemaining ?? this.traysRemaining,
    discards: discards ?? this.discards,
    gold: gold ?? this.gold,
    status: status ?? this.status,
    placements: placements ?? this.placements,
    actions: actions ?? this.actions,
    endless: endless ?? this.endless,
    skipped: skipped ?? this.skipped,
    consumables: consumables ?? this.consumables,
    vouchers: vouchers ?? this.vouchers,
    archetypeLevels: archetypeLevels ?? this.archetypeLevels,
    archetypesThisBlind: archetypesThisBlind ?? this.archetypesThisBlind,
    shop: clearShop ? null : (shop ?? this.shop),
    boss: clearBoss ? null : (boss ?? this.boss),
    scoreSerial: scoreSerial ?? this.scoreSerial,
    lastScore: lastScore ?? this.lastScore,
    preClearBoard: preClearBoard ?? this.preClearBoard,
  );
}
