import 'dart:math';

import 'ante_scaling.dart';

/// Blind reward payouts and interest. Placeholder balance values.
/// Itemized cash-out shown after a blind falls.
class CashOutBreakdown {
  const CashOutBreakdown({
    required this.reward,
    required this.traysBonus,
    required this.interest,
    required this.jokerBonus,
  });

  final int reward;
  final int traysBonus;
  final int interest;
  final int jokerBonus;

  int get total => reward + traysBonus + interest + jokerBonus;
}

abstract final class BlindEconomy {
  /// Small pays this; Big (1.5x) and Boss (2x) scale with the blind.
  static const int baseReward = 4;

  /// $1 interest per $5 held, capped.
  static const int interestStep = 5;
  static const int interestCap = 5;

  static int reward(BlindType blind) => (baseReward * blind.multiplier).round();

  static int interest(int gold, {int cap = interestCap}) {
    if (gold <= 0) return 0;
    final earned = gold ~/ interestStep;
    return earned > cap ? cap : earned;
  }

  /// Total cash after beating [blind]: reward + interest on current gold +
  /// [bonus] (e.g. leftover trays/discards).
  static int payout(BlindType blind, {required int gold, int bonus = 0}) =>
      reward(blind) + interest(gold) + bonus;

  /// Base reward + $1 per unused tray + interest (+ joker bonuses).
  /// [traysRemaining] counts the tray in play, which is not "unused".
  static CashOutBreakdown breakdown(
    BlindType blind, {
    required int gold,
    required int traysRemaining,
    int jokerBonus = 0,
    int interestCap = BlindEconomy.interestCap,
  }) => CashOutBreakdown(
    reward: reward(blind),
    traysBonus: max(0, traysRemaining - 1),
    interest: interest(gold, cap: interestCap),
    jokerBonus: jokerBonus,
  );
}
