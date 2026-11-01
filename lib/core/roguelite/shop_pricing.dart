import 'dart:math';

import 'ante_scaling.dart';

/// Shop price math: Ante inflation, vouchers' discount, and reroll cost.
abstract final class ShopPricing {
  static const int baseRerollCost = 5;

  /// Each consecutive reroll in one shop visit costs this much more.
  static const int rerollStep = 2;

  /// The price shown in the shop: [basePrice] x the Ante multiplier x
  /// (1 - [discount]), rounded to whole dollars (never below $1).
  static int price(int basePrice, {required int ante, double discount = 0}) =>
      max(
        1,
        (basePrice * AnteScaling.priceMultiplier(ante) * (1 - discount))
            .round(),
      );

  /// $5, then $7, $9, $11... Resets with every new shop visit. Reroll prices
  /// do not inflate with the Ante.
  static int rerollCost(int rerolls) => baseRerollCost + rerollStep * rerolls;
}
