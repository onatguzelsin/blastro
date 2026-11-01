import 'dart:math';

import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/core/roguelite/shop_pricing.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generated stock uses the inflated prices', () {
    for (final ante in [1, 4, 8, 16]) {
      test('Ante $ante', () {
        for (var seed = 0; seed < 25; seed++) {
          for (final item in ShopGenerator.generate(Random(seed), ante: ante)) {
            final base = switch (item.kind) {
              ShopItemKind.joker => JokerRegistry.byId(item.id).basePrice,
              ShopItemKind.consumable => ConsumableRegistry.byId(
                item.id,
              ).basePrice,
              ShopItemKind.voucher => Voucher.basePrice,
            };
            expect(
              item.price,
              ShopPricing.price(base, ante: ante),
              reason: '${item.id} at ante $ante',
            );
          }
        }
      });
    }

    test('a Clearance Sale discount lowers every price', () {
      final full = ShopGenerator.generate(Random(5), ante: 4);
      final sale = ShopGenerator.generate(Random(5), ante: 4, discount: 0.25);
      expect(sale.map((i) => i.id), full.map((i) => i.id));
      for (var i = 0; i < full.length; i++) {
        expect(sale[i].price, lessThan(full[i].price));
      }
    });

    test('Overstock adds a third joker', () {
      final base = ShopGenerator.generate(Random(5));
      final more = ShopGenerator.generate(Random(5), extraJokerSlots: 1);
      expect(base.where((i) => i.isJoker).length, 2);
      expect(more.where((i) => i.isJoker).length, 3);
    });

    test('an owned voucher never shows up again', () {
      final all = VoucherRegistry.all.map((v) => v.id).toSet();
      for (var seed = 0; seed < 40; seed++) {
        final owned = {
          VoucherRegistry.overstock.id,
          VoucherRegistry.wasteful.id,
        };
        final stock = ShopGenerator.generate(
          Random(seed),
          ownedVoucherIds: owned,
        );
        final v = stock.where((i) => i.isVoucher).single;
        expect(owned.contains(v.id), isFalse);
        expect(all.contains(v.id), isTrue);
      }
      final none = ShopGenerator.generate(Random(1), ownedVoucherIds: all);
      expect(none.where((i) => i.isVoucher), isEmpty);
    });
  });

  group('rarity weighting', () {
    test('Legendary is rare, Common is most common (deterministic)', () {
      final counts = {for (final r in JokerRarity.values) r: 0};
      var total = 0;
      for (var seed = 0; seed < 3000; seed++) {
        for (final item in ShopGenerator.generate(
          Random(seed),
        ).where((i) => i.isJoker)) {
          counts[JokerRegistry.byId(item.id).rarity] =
              counts[JokerRegistry.byId(item.id).rarity]! + 1;
          total++;
        }
      }
      double share(JokerRarity r) => counts[r]! / total;
      expect(share(JokerRarity.common), inInclusiveRange(0.45, 0.62));
      expect(share(JokerRarity.uncommon), inInclusiveRange(0.24, 0.36));
      expect(share(JokerRarity.rare), inInclusiveRange(0.08, 0.17));
      expect(share(JokerRarity.legendary), inInclusiveRange(0.015, 0.05));
    });

    test(
      'the same seed gives the same shop; no duplicate jokers in one shop',
      () {
        for (var seed = 0; seed < 50; seed++) {
          final a = ShopGenerator.generate(Random(seed), extraJokerSlots: 1);
          final b = ShopGenerator.generate(Random(seed), extraJokerSlots: 1);
          expect(a.map((i) => i.id), b.map((i) => i.id));
          final ids = a.where((i) => i.isJoker).map((i) => i.id);
          expect(ids.toSet().length, ids.length);
        }
      },
    );
  });

  group('ShopItem JSON', () {
    test('round trips every kind', () {
      for (final item in ShopGenerator.generate(Random(3), ante: 5)) {
        final back = ShopItem.fromJson(item.toJson());
        expect(
          [back.id, back.kind, back.price],
          [item.id, item.kind, item.price],
        );
      }
    });

    test('reads older saves that only stored a joker flag', () {
      final joker = ShopItem.fromJson({
        'id': 'joker_plain',
        'joker': true,
        'price': 4,
      });
      final card = ShopItem.fromJson({
        'id': 'chisel_bonus',
        'joker': false,
        'price': 3,
      });
      expect(joker.kind, ShopItemKind.joker);
      expect(card.kind, ShopItemKind.consumable);
    });
  });
}
