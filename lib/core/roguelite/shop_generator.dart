import 'dart:math';

import 'consumables.dart';
import 'joker_registry.dart';
import 'shop_pricing.dart';
import 'vouchers.dart';

enum ShopItemKind { joker, consumable, voucher }

class ShopItem {
  const ShopItem({required this.id, required this.kind, required this.price});

  /// Reads both the current format (`kind`) and older saves, which stored
  /// only a `joker` flag.
  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as String,
    kind: json['kind'] != null
        ? ShopItemKind.values.byName(json['kind'] as String)
        : (json['joker'] == true
              ? ShopItemKind.joker
              : ShopItemKind.consumable),
    price: json['price'] as int,
  );

  final String id;
  final ShopItemKind kind;

  /// What you pay now: base price x Ante inflation x any voucher discount.
  final int price;

  bool get isJoker => kind == ShopItemKind.joker;
  bool get isVoucher => kind == ShopItemKind.voucher;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'price': price,
  };
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
  static const int maxJokers = 5;

  /// Jokers (never ones you own), cards and one voucher, drawn with [rng].
  /// Joker rarity is weighted (common 55, uncommon 30, rare 12, legendary 3).
  /// Prices include Ante inflation and the voucher [discount].
  static List<ShopItem> generate(
    Random rng, {
    Set<String> ownedJokerIds = const {},
    Set<String> ownedVoucherIds = const {},
    int ante = 1,
    double discount = 0,
    int extraJokerSlots = 0,
  }) {
    int priced(int base) =>
        ShopPricing.price(base, ante: ante, discount: discount);
    final jokers = _drawJokers(
      rng,
      JokerRegistry.all.where((d) => !ownedJokerIds.contains(d.id)).toList(),
      jokerSlots + extraJokerSlots,
    );
    final cards = [...ConsumableRegistry.all]..shuffle(rng);
    final vouchers =
        VoucherRegistry.all
            .where((v) => !ownedVoucherIds.contains(v.id))
            .toList()
          ..shuffle(rng);
    return [
      for (final d in jokers)
        ShopItem(
          id: d.id,
          kind: ShopItemKind.joker,
          price: priced(d.basePrice),
        ),
      for (final c in cards.take(consumableSlots))
        ShopItem(
          id: c.id,
          kind: ShopItemKind.consumable,
          price: priced(c.basePrice),
        ),
      for (final v in vouchers.take(1))
        ShopItem(
          id: v.id,
          kind: ShopItemKind.voucher,
          price: priced(Voucher.basePrice),
        ),
    ];
  }

  /// Weighted draw without replacement: roll the rarity tier by its weight
  /// (among tiers that still have jokers), then pick uniformly inside it. So
  /// Legendary really is ~3% of draws even though there are only 3 of them.
  static List<JokerDef> _drawJokers(
    Random rng,
    List<JokerDef> pool,
    int count,
  ) {
    final out = <JokerDef>[];
    while (out.length < count && pool.isNotEmpty) {
      final tiers = JokerRarity.values
          .where((r) => pool.any((d) => d.rarity == r))
          .toList();
      var roll = rng.nextInt(tiers.fold<int>(0, (sum, r) => sum + r.weight));
      final tier = tiers.firstWhere((r) => (roll -= r.weight) < 0);
      final inTier = pool.where((d) => d.rarity == tier).toList();
      final pick = inTier[rng.nextInt(inTier.length)];
      out.add(pick);
      pool.remove(pick);
    }
    return out;
  }

  /// Cost of the next reroll: $5, then +$2 for each reroll already done in
  /// this shop visit.
  static int rerollCost(int rerolls) => ShopPricing.rerollCost(rerolls);

  static BuyResult canBuy(
    ShopItem item, {
    required int gold,
    required int jokerCount,
    required int consumableCount,
    required Set<String> ownedJokerIds,
    Set<String> ownedVoucherIds = const {},
  }) {
    if (item.isJoker && ownedJokerIds.contains(item.id)) {
      return BuyResult.alreadyOwned;
    }
    if (item.isVoucher && ownedVoucherIds.contains(item.id)) {
      return BuyResult.alreadyOwned;
    }
    final full = switch (item.kind) {
      ShopItemKind.joker => jokerCount >= maxJokers,
      ShopItemKind.consumable => consumableCount >= Consumable.maxHeld,
      ShopItemKind.voucher => false,
    };
    if (full) return BuyResult.noSlot;
    return gold < item.price ? BuyResult.tooExpensive : BuyResult.ok;
  }
}
