import 'dart:math';

import 'consumables.dart';
import 'joker_registry.dart';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.isJoker,
    required this.price,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as String,
    isJoker: json['joker'] as bool,
    price: json['price'] as int,
  );

  final String id;
  final bool isJoker;
  final int price;

  Map<String, dynamic> toJson() => {'id': id, 'joker': isJoker, 'price': price};
}

/// The shop's current stock and how many times it was rerolled.
class ShopState {
  const ShopState({required this.stock, this.rerolls = 0});

  factory ShopState.fromJson(Map<String, dynamic> json) => ShopState(
    stock: [
      for (final i in json['stock'] as List<dynamic>)
        ShopItem.fromJson(i as Map<String, dynamic>),
    ],
    rerolls: json['rerolls'] as int,
  );

  final List<ShopItem> stock;
  final int rerolls;

  Map<String, dynamic> toJson() => {
    'stock': [for (final i in stock) i.toJson()],
    'rerolls': rerolls,
  };
}

enum BuyResult { ok, tooExpensive, noSlot, alreadyOwned }

abstract final class ShopGenerator {
  static const int jokerSlots = 2;
  static const int consumableSlots = 2;
  static const int baseRerollCost = 5;
  static const int maxJokers = 5;

  /// 2 jokers (never ones you own) + 2 consumables, drawn with [rng].
  static List<ShopItem> generate(
    Random rng, {
    Set<String> ownedJokerIds = const {},
  }) {
    final jokers =
        JokerRegistry.all.where((d) => !ownedJokerIds.contains(d.id)).toList()
          ..shuffle(rng);
    final cards = [...ConsumableRegistry.all]..shuffle(rng);
    return [
      for (final d in jokers.take(jokerSlots))
        ShopItem(id: d.id, isJoker: true, price: d.price),
      for (final c in cards.take(consumableSlots))
        ShopItem(id: c.id, isJoker: false, price: Consumable.price),
    ];
  }

  /// Cost of the next reroll: $5, then +$1 per reroll already done.
  static int rerollCost(int rerolls) => baseRerollCost + rerolls;

  static BuyResult canBuy(
    ShopItem item, {
    required int gold,
    required int jokerCount,
    required int consumableCount,
    required Set<String> ownedJokerIds,
  }) {
    if (item.isJoker && ownedJokerIds.contains(item.id)) {
      return BuyResult.alreadyOwned;
    }
    final full = item.isJoker
        ? jokerCount >= maxJokers
        : consumableCount >= Consumable.maxHeld;
    if (full) return BuyResult.noSlot;
    return gold < item.price ? BuyResult.tooExpensive : BuyResult.ok;
  }
}
