import 'dart:math';

enum BlindType {
  small(1.0),
  big(1.5),
  boss(2.0);

  const BlindType(this.multiplier);

  /// `Small Blind`, `Big Blind` or `Boss Blind`.
  String get displayName => switch (this) {
    BlindType.small => 'Small Blind',
    BlindType.big => 'Big Blind',
    BlindType.boss => 'Boss Blind',
  };

  /// Scales both the target score and the cash reward.
  final double multiplier;
}

/// Ante 1-8 base targets, then Endless Mode (Ante 9-39).
/// Ante 8 Boss = 2 x 50,000 = 100,000 (the Finisher).
abstract final class AnteScaling {
  static const int finalAnte = 8;
  static const int lastEndlessAnte = 39;

  static const List<int> _baseTable = [
    300, 800, 2000, 5000, 11000, 20000, 35000, 50000, //
  ];

  /// Endless growth per ante, rounded to the nearest 1,000.
  static const double endlessGrowth = 1.6;

  static bool isEndless(int ante) => ante > finalAnte;

  /// Shop prices rise 15% per Ante from Ante 2 up to the Ante 8 Finisher
  /// (x2.05 there), then 10% per Ante in Endless Mode (x5.15 at Ante 39).
  static const double priceInflationPerAnte = 0.15;
  static const double endlessPriceInflationPerAnte = 0.10;

  static double priceMultiplier(int ante) {
    final standard = min(max(ante, 1), finalAnte) - 1;
    final endless = max(0, ante - finalAnte);
    return 1 +
        priceInflationPerAnte * standard +
        endlessPriceInflationPerAnte * endless;
  }

  static int baseTarget(int ante) {
    if (ante < 1 || ante > lastEndlessAnte) {
      throw RangeError.range(ante, 1, lastEndlessAnte, 'ante');
    }
    if (ante <= finalAnte) return _baseTable[ante - 1];
    final raw = _baseTable.last * pow(endlessGrowth, ante - finalAnte);
    return (raw / 1000).round() * 1000;
  }

  static int blindTarget(int ante, BlindType blind) =>
      (baseTarget(ante) * blind.multiplier).round();

  /// Target for a blind, honoring a Boss's own target multiplier (e.g. The
  /// Wall's 4x). [bossMultiplier] only applies to the Boss Blind.
  static int targetFor(int ante, BlindType blind, {double? bossMultiplier}) {
    final factor = (blind == BlindType.boss && bossMultiplier != null)
        ? bossMultiplier
        : blind.multiplier;
    return (baseTarget(ante) * factor).round();
  }

  /// The 100,000-point Ante 8 Boss that ends the standard run.
  static bool isFinisher(int ante, BlindType blind) =>
      ante == finalAnte && blind == BlindType.boss;
}
