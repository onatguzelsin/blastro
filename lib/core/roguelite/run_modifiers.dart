import 'joker_effects.dart';

/// Run-wide rule changes granted by the joker bar.
class RunModifiers {
  const RunModifiers({
    this.rotation = false,
    this.extraSetupMoves = 0,
    this.extraDiscards = 0,
    this.extraTrays = 0,
    this.cashOutBonus = 0,
    this.luckyAlways = false,
    this.steelMultiplier = defaultSteelMultiplier,
    this.interestCap = defaultInterestCap,
    this.priceDiscount = 0,
    this.shopJokerSlots = 0,
  });

  static const double defaultSteelMultiplier = 1.5;
  static const int defaultInterestCap = 5;
  static const RunModifiers none = RunModifiers();

  /// Aggregates every joker on the bar.
  factory RunModifiers.fromJokers(List<Joker> jokers) =>
      RunModifiers.combine([for (final j in jokers) j.modifiers]);

  /// Jokers plus the modifiers of owned vouchers.
  factory RunModifiers.fromRun(
    List<Joker> jokers,
    Iterable<RunModifiers> extras,
  ) => RunModifiers.combine([for (final j in jokers) j.modifiers, ...extras]);

  /// Additive where it makes sense, OR for switches, max for caps.
  factory RunModifiers.combine(Iterable<RunModifiers> parts) {
    var out = none;
    for (final m in parts) {
      out = RunModifiers(
        rotation: out.rotation || m.rotation,
        extraSetupMoves: out.extraSetupMoves + m.extraSetupMoves,
        extraDiscards: out.extraDiscards + m.extraDiscards,
        extraTrays: out.extraTrays + m.extraTrays,
        cashOutBonus: out.cashOutBonus + m.cashOutBonus,
        luckyAlways: out.luckyAlways || m.luckyAlways,
        steelMultiplier: m.steelMultiplier > out.steelMultiplier
            ? m.steelMultiplier
            : out.steelMultiplier,
        interestCap: m.interestCap > out.interestCap
            ? m.interestCap
            : out.interestCap,
        priceDiscount: out.priceDiscount + m.priceDiscount,
        shopJokerSlots: out.shopJokerSlots + m.shopJokerSlots,
      );
    }
    return out;
  }

  /// Tray pieces can be rotated (Gyroscope).
  final bool rotation;

  /// Extra non-clearing placements the combo window survives.
  final int extraSetupMoves;
  final int extraDiscards;
  final int extraTrays;
  final int cashOutBonus;

  /// Lucky cells always trigger.
  final bool luckyAlways;

  /// Mult factor for Steel residue cells (Baron of Steel raises it).
  final double steelMultiplier;

  /// Most interest you can earn at cash out (Seed Money raises it).
  final int interestCap;

  /// Fraction taken off future shop prices (Clearance Sale), 0..1.
  final double priceDiscount;

  /// Extra jokers for sale in every shop (Overstock).
  final int shopJokerSlots;
}
