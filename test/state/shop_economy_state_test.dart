import 'dart:convert';

import 'package:blastro/core/polyomino/block_bag.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/core/roguelite/shop_pricing.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_state_codec.dart';
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

void main() {
  group('reroll escalation within one shop visit', () {
    test('costs \$5, \$7, \$9 and charges exactly that', () {
      final c = _container();
      final n = _cleared(c, gold: 200)..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 100));
      final paid = <int>[];
      for (var i = 0; i < 4; i++) {
        final before = c.read(runProvider).gold;
        n.rerollShop();
        paid.add(before - c.read(runProvider).gold);
      }
      expect(paid, [5, 7, 9, 11]);
      expect(c.read(runProvider).shop!.rerolls, 4);
    });

    test('a reroll you cannot afford changes nothing', () {
      final c = _container();
      final n = _cleared(c)..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 4));
      final stock = c.read(runProvider).shop!.stock.map((i) => i.id).toList();
      n.rerollShop();
      expect(c.read(runProvider).gold, 4);
      expect(c.read(runProvider).shop!.stock.map((i) => i.id).toList(), stock);
    });

    test('the cost resets to \$5 at the next shop visit', () {
      final c = _container();
      final n = _cleared(c, gold: 300)..collectCashOut();
      n.rerollShop();
      n.rerollShop();
      expect(c.read(runProvider).shop!.rerolls, 2);
      n.leaveShop();
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(status: RunStatus.blindCleared, traysRemaining: 1),
      );
      n.collectCashOut();
      expect(c.read(runProvider).shop!.rerolls, 0);
      final before = c.read(runProvider).gold;
      n.rerollShop();
      expect(before - c.read(runProvider).gold, 5);
    });
  });

  group('stock prices follow the Ante', () {
    for (final ante in [1, 2, 4, 8, 12]) {
      test('Ante $ante', () {
        final c = _container();
        _cleared(c, ante: ante).collectCashOut();
        for (final item in c.read(runProvider).shop!.stock) {
          expect(
            item.price,
            ShopPricing.price(_baseOf(item), ante: ante),
            reason: '${item.id} at ante $ante',
          );
        }
      });
    }

    test('buying at Ante 4 charges the inflated price', () {
      final c = _container();
      final n = _cleared(c, ante: 4, gold: 200)..collectCashOut();
      n.debugSet(c.read(runProvider).copyWith(gold: 200));
      final joker = c
          .read(runProvider)
          .shop!
          .stock
          .firstWhere((i) => i.isJoker);
      expect(
        joker.price,
        greaterThan(JokerRegistry.byId(joker.id).basePrice),
        reason: 'inflated above base',
      );
      n.buyItem(joker.id);
      expect(c.read(runProvider).gold, 200 - joker.price);
    });

    test('selling pays half the BASE price even at Ante 8', () {
      final c = _container();
      final n = _cleared(c, ante: 8)..collectCashOut();
      n.debugSet(
        c
            .read(runProvider)
            .copyWith(
              gold: 0,
              jokers: [JokerRegistry.byId('joker_blueprint').joker],
            ),
      );
      n.sellJoker(0);
      expect(c.read(runProvider).gold, 8, reason: 'half of base \$16');
    });
  });

  group('saving', () {
    test('vouchers and item kinds survive a save round trip', () {
      final c = _container();
      _cleared(
        c,
        ante: 3,
        vouchers: [VoucherRegistry.seedMoney.id],
      ).collectCashOut();
      final s = c.read(runProvider);
      final json = jsonDecode(
        jsonEncode(RunStateCodec.encode(s, BlockBag(1).snapshot())),
      ) as Map<String, dynamic>;
      final back = RunStateCodec.decode(json).state;
      expect(back.vouchers, [VoucherRegistry.seedMoney.id]);
      expect(
        back.shop!.stock.map((i) => [i.id, i.kind, i.price]).toList(),
        s.shop!.stock.map((i) => [i.id, i.kind, i.price]).toList(),
      );
      expect(back.modifiers.interestCap, 10);
    });

    test('an older save without vouchers or item kinds still loads', () {
      final c = _container();
      _cleared(c).collectCashOut();
      final json = jsonDecode(
        jsonEncode(
          RunStateCodec.encode(c.read(runProvider), BlockBag(1).snapshot()),
        ),
      ) as Map<String, dynamic>;
      json.remove('vouchers');
      final stock = (json['shop'] as Map<String, dynamic>)['stock'] as List;
      for (final item in stock.cast<Map<String, dynamic>>()) {
        item['joker'] = item['kind'] == 'joker';
        item.remove('kind');
      }
      final back = RunStateCodec.decode(json).state;
      expect(back.vouchers, isEmpty);
      expect(back.shop!.stock.length, stock.length);
      expect(back.shop!.stock.where((i) => i.isJoker), isNotEmpty);
      expect(AnteScaling.priceMultiplier(back.ante), 1.0);
    });
  });
}
