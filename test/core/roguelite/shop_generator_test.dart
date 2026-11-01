import 'dart:math';

import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_economy.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stock: 2 jokers + 2 cards + 1 voucher, seeded and reproducible', () {
    final a = ShopGenerator.generate(Random(7));
    final b = ShopGenerator.generate(Random(7));
    expect(a.map((i) => i.id), b.map((i) => i.id));
    expect(a.where((i) => i.isJoker).length, 2);
    expect(a.where((i) => i.kind == ShopItemKind.consumable).length, 2);
    expect(a.where((i) => i.isVoucher).length, 1);
    expect(
      ShopGenerator.generate(Random(8)).map((i) => i.id),
      isNot(a.map((i) => i.id)),
    );
  });

  test('never offers jokers you already own', () {
    final owned = {
      'joker_plain', 'joker_amplifier', 'joker_cornerstone', //
    };
    for (var s = 0; s < 30; s++) {
      final jokers = ShopGenerator.generate(
        Random(s),
        ownedJokerIds: owned,
      ).where((i) => i.isJoker);
      expect(jokers.any((i) => owned.contains(i.id)), isFalse);
    }
  });

  test('reroll cost starts at \$5 and rises \$2 per reroll', () {
    expect(
      [for (var i = 0; i < 5; i++) ShopGenerator.rerollCost(i)],
      [5, 7, 9, 11, 13],
    );
  });

  test('canBuy: ok, tooExpensive, noSlot, alreadyOwned', () {
    const joker = ShopItem(
      id: 'joker_plain',
      kind: ShopItemKind.joker,
      price: 6,
    );
    const card = ShopItem(
      id: 'chisel_bonus',
      kind: ShopItemKind.consumable,
      price: 6,
    );
    BuyResult buy(
      ShopItem i, {
      int gold = 10,
      int jokers = 0,
      int cards = 0,
      Set<String> owned = const {},
    }) => ShopGenerator.canBuy(
      i,
      gold: gold,
      jokerCount: jokers,
      consumableCount: cards,
      ownedJokerIds: owned,
    );
    expect(buy(joker), BuyResult.ok);
    expect(buy(joker, gold: 5), BuyResult.tooExpensive);
    expect(buy(joker, jokers: 5), BuyResult.noSlot);
    expect(buy(card, cards: 2), BuyResult.noSlot);
    expect(buy(card, jokers: 5), BuyResult.ok);
    expect(buy(joker, owned: {'joker_plain'}), BuyResult.alreadyOwned);
  });

  test('ShopState JSON round trip', () {
    final s = ShopState(stock: ShopGenerator.generate(Random(1)), rerolls: 2);
    final back = ShopState.fromJson(s.toJson());
    expect(back.rerolls, 2);
    expect(back.stock.map((i) => i.id), s.stock.map((i) => i.id));
  });

  test(
    'cash-out breakdown: reward + unused trays + interest + joker bonus',
    () {
      final b = BlindEconomy.breakdown(
        BlindType.big,
        gold: 12,
        traysRemaining: 4,
        jokerBonus: 2,
      );
      expect([b.reward, b.traysBonus, b.interest, b.jokerBonus], [6, 3, 2, 2]);
      expect(b.total, 13);
      expect(
        BlindEconomy.breakdown(
          BlindType.small,
          gold: 0,
          traysRemaining: 0,
        ).total,
        4,
      );
    },
  );
}
