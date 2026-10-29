import 'dart:math';

enum BlindType {
  small(1.0),
  big(1.5),
  boss(2.0);

  const BlindType(this.multiplier);

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

  /// The 100,000-point Ante 8 Boss that ends the standard run.
  static bool isFinisher(int ante, BlindType blind) =>
      ante == finalAnte && blind == BlindType.boss;
}
