import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/core/roguelite/shop_pricing.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(11);
  return c;
}

/// A run at the cash-out screen of [ante]'s Small Blind with [gold].
RunNotifier _cleared(
  ProviderContainer c, {
  int ante = 1,
  int gold = 100,
  List<String> vouchers = const [],
}) {
  final n = c.read(runProvider.notifier);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          status: RunStatus.blindCleared,
          ante: ante,
          gold: gold,
          traysRemaining: 3,
          vouchers: vouchers,
        ),
  );
  return n;
}

int _baseOf(ShopItem i) => switch (i.kind) {
  ShopItemKind.joker => JokerRegistry.byId(i.id).basePrice,
  ShopItemKind.consumable => ConsumableRegistry.byId(i.id).basePrice,
  ShopItemKind.voucher => Voucher.basePrice,
};

ShopItem _voucherInShop(ProviderContainer c) =>
    c.read(runProvider).shop!.stock.firstWhere((i) => i.isVoucher);

void main() {
  group('vouchers', () {
    test('buying one adds it for the run and spends its price', () {
      final c = _container();
      final n = _cleared(c, gold: 100)..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 100));
      final v = _voucherInShop(c);
      expect(v.price, 12);
      n.buyItem(v.id);
      expect(c.read(runProvider).vouchers, [v.id]);
      expect(c.read(runProvider).gold, 88);
      expect(c.read(runProvider).shop!.stock.any((i) => i.id == v.id), isFalse);
    });

    test('cannot be bought without the money', () {
      final c = _container();
      final n = _cleared(c)..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 11));
      n.buyItem(_voucherInShop(c).id);
      expect(c.read(runProvider).vouchers, isEmpty);
      expect(c.read(runProvider).gold, 11);
    });

    test('an owned voucher is not offered again, even after rerolls', () {
      final c = _container();
      final n = _cleared(c, gold: 500, vouchers: [VoucherRegistry.overstock.id])
        ..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 500));
      for (var i = 0; i < 12; i++) {
        n.rerollShop();
        final v = c.read(runProvider).shop!.stock.where((i) => i.isVoucher);
        expect(v.any((i) => i.id == VoucherRegistry.overstock.id), isFalse);
      }
    });

    test('Seed Money lifts the interest cap from \$5 to \$10', () {
      final c = _container();
      _cleared(
        c,
        gold: 100,
        vouchers: [VoucherRegistry.seedMoney.id],
      ).collectCashOut();
      // 100 gold: \$10 interest (capped) + \$4 reward + \$2 unused trays.
      expect(c.read(runProvider).gold, 100 + 4 + 2 + 10);
      final c2 = _container();
      _cleared(c2, gold: 100).collectCashOut();
      expect(c2.read(runProvider).gold, 100 + 4 + 2 + 5);
    });

    test('Wasteful gives +1 discard from the next blind on', () {
      final c = _container();
      final n = _cleared(c, vouchers: [VoucherRegistry.wasteful.id])
        ..collectCashOut();
      n.leaveShop();
      n.playBlind();
      expect(c.read(runProvider).discards, RunState.discardsPerBlind + 1);
    });

    test('Overstock puts a third joker in every shop', () {
      final c = _container();
      _cleared(c, vouchers: [VoucherRegistry.overstock.id]).collectCashOut();
      expect(c.read(runProvider).shop!.stock.where((i) => i.isJoker).length, 3);
    });

    test('Clearance Sale makes the next shop and its rerolls 25% cheaper', () {
      final c = _container();
      final n = _cleared(
        c,
        ante: 4,
        gold: 300,
        vouchers: [VoucherRegistry.clearanceSale.id],
      )..collectCashOut();
      void expectDiscounted() {
        for (final item in c.read(runProvider).shop!.stock) {
          expect(
            item.price,
            ShopPricing.price(_baseOf(item), ante: 4, discount: 0.25),
            reason: item.id,
          );
        }
      }

      expectDiscounted();
      n.rerollShop();
      expectDiscounted();
    });

    test('buying Clearance Sale does not reprice the shop on screen', () {
      final c = _container();
      final n = _cleared(c, ante: 2)..collectCashOut();
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              gold: 200,
              shop: const ShopState(
                stock: [
                  ShopItem(
                    id: 'voucher_clearance_sale',
                    kind: ShopItemKind.voucher,
                    price: 14,
                  ),
                  ShopItem(
                    id: 'joker_plain',
                    kind: ShopItemKind.joker,
                    price: 7,
                  ),
                ],
              ),
            ),
      );
      n.buyItem('voucher_clearance_sale');
      expect(c.read(runProvider).shop!.stock.single.price, 7);
    });

    test('vouchers stack with jokers: Wasteful + Discard Hoarder = +2', () {
      final c = _container();
      final n = _cleared(c, vouchers: [VoucherRegistry.wasteful.id])
        ..collectCashOut();
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              jokers: [JokerRegistry.byId('joker_discard_hoarder').joker],
            ),
      );
      n.leaveShop();
      n.playBlind();
      expect(c.read(runProvider).discards, RunState.discardsPerBlind + 2);
    });
  });
}
