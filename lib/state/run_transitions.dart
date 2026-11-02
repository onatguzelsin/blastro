import 'dart:math';

import '../core/roguelite/blind_economy.dart';
import '../core/roguelite/boss_blinds.dart';
import '../core/roguelite/consumables.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/ante_scaling.dart';
import '../core/roguelite/shop_generator.dart';
import 'run_state.dart';

/// Pure cash-out / shop / consumable state transitions. Each returns the
/// input unchanged when the action is not allowed.
abstract final class RunTransitions {
  static Random rng(RunState s) =>
      Random(s.seed + s.placements * 1000 + s.actions * 7);

  static CashOutBreakdown cashOut(RunState s) => BlindEconomy.breakdown(
    s.blind,
    gold: s.gold,
    traysRemaining: s.traysRemaining,
    jokerBonus: s.modifiers.cashOutBonus,
    interestCap: s.modifiers.interestCap,
  );

  static Set<String> _owned(RunState s) => {for (final j in s.jokers) j.id};

  /// A fresh batch of shop items at this run's Ante, with voucher perks.
  static List<ShopItem> _stock(RunState s) {
    final mods = s.modifiers;
    return ShopGenerator.generate(
      rng(s),
      ownedJokerIds: _owned(s),
      ownedVoucherIds: s.vouchers.toSet(),
      ante: s.ante,
      discount: mods.priceDiscount,
      extraJokerSlots: mods.shopJokerSlots,
    );
  }

  static RunState collectCashOut(RunState s) {
    if (s.status != RunStatus.blindCleared) return s;
    final paid = s.copyWith(
      gold: s.gold + cashOut(s).total,
      status: RunStatus.shopping,
      actions: s.actions + 1,
    );
    return paid.copyWith(shop: ShopState(stock: _stock(paid)));
  }

  static RunState buy(RunState s, String itemId) {
    final shop = s.shop;
    if (s.status != RunStatus.shopping || shop == null) return s;
    final item = shop.stock.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return s;
    final ok = ShopGenerator.canBuy(
      item,
      gold: s.gold,
      jokerCount: s.jokers.length,
      consumableCount: s.consumables.length,
      ownedJokerIds: _owned(s),
      ownedVoucherIds: s.vouchers.toSet(),
    );
    if (ok != BuyResult.ok) return s;
    return s.copyWith(
      gold: s.gold - item.price,
      jokers: item.isJoker
          ? [...s.jokers, JokerRegistry.byId(item.id).joker]
          : null,
      consumables: item.kind == ShopItemKind.consumable
          ? [...s.consumables, item.id]
          : null,
      vouchers: item.isVoucher ? [...s.vouchers, item.id] : null,
      shop: ShopState(
        stock: [
          for (final i in shop.stock)
            if (i.id != itemId) i,
        ],
        rerolls: shop.rerolls,
      ),
      actions: s.actions + 1,
    );
  }

  static RunState reroll(RunState s) {
    final shop = s.shop;
    if (s.status != RunStatus.shopping || shop == null) return s;
    final cost = ShopGenerator.rerollCost(shop.rerolls);
    if (s.gold < cost) return s;
    final paid = s.copyWith(gold: s.gold - cost, actions: s.actions + 1);
    return paid.copyWith(
      shop: ShopState(stock: _stock(paid), rerolls: shop.rerolls + 1),
    );
  }

  static RunState sellJoker(RunState s, int index) {
    if (s.status != RunStatus.shopping ||
        index < 0 ||
        index >= s.jokers.length) {
      return s;
    }
    final def = JokerRegistry.maybeById(s.jokers[index].id);
    return s.copyWith(
      gold: s.gold + (def?.sellValue ?? 0),
      jokers: [...s.jokers]..removeAt(index),
      actions: s.actions + 1,
    );
  }

  /// Uses the held consumable at [index] (shop or mid-run).
  static RunState useConsumable(RunState s, int index) {
    if (index < 0 || index >= s.consumables.length) return s;
    if (s.status != RunStatus.playing && s.status != RunStatus.shopping) {
      return s;
    }
    final card = ConsumableRegistry.byId(s.consumables[index]);
    final rest = [...s.consumables]..removeAt(index);
    final used = s.copyWith(consumables: rest, actions: s.actions + 1);
    return switch (card) {
      BlueprintCard() => used.copyWith(
        archetypeLevels: card.levelUp(s.archetypeLevels),
      ),
      ChiselCard() =>
        card.canUse(s.grid)
            ? used.copyWith(grid: card.apply(s.grid, rng(used)))
            : s,
    };
  }

  /// Gyroscope: rotate the piece in tray [slot].
  static RunState rotate(RunState s, int slot) {
    final piece = s.tray[slot];
    if (!s.modifiers.rotation || piece == null) return s;
    return s.copyWith(tray: [...s.tray]..[slot] = piece.nextVariant);
  }

  /// Sets trays, discards and the Boss for the blind now in [s.blind].
  static RunState beginBlind(RunState s) {
    final mods = s.modifiers;
    final boss = s.blind == BlindType.boss
        ? BossRegistry.pick(s.ante, s.seed)
        : null;
    return s.copyWith(
      traysRemaining:
          boss?.fixedTrays ?? s.deck.traysPerBlind + mods.extraTrays,
      discards: (boss?.noDiscards ?? false)
          ? 0
          : s.deck.discardsPerBlind + mods.extraDiscards,
      boss: boss,
      clearBoss: boss == null,
      archetypesThisBlind: const [],
      score: 0,
    );
  }
}
