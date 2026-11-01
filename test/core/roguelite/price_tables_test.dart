import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/core/roguelite/shop_pricing.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ante price inflation', () {
    test('no inflation at Ante 1, +15% per Ante from Ante 2', () {
      expect(AnteScaling.priceMultiplier(1), 1.0);
      expect(AnteScaling.priceMultiplier(2), closeTo(1.15, 1e-9));
      expect(AnteScaling.priceMultiplier(3), closeTo(1.30, 1e-9));
      expect(AnteScaling.priceMultiplier(4), closeTo(1.45, 1e-9));
      expect(AnteScaling.priceMultiplier(8), closeTo(2.05, 1e-9));
    });

    test('Endless Mode inflates more slowly: +10% per Ante after Ante 8', () {
      expect(AnteScaling.priceMultiplier(9), closeTo(2.15, 1e-9));
      expect(AnteScaling.priceMultiplier(16), closeTo(2.85, 1e-9));
      expect(AnteScaling.priceMultiplier(39), closeTo(5.15, 1e-9));
    });

    test('strictly rising every Ante, and sane below Ante 1', () {
      for (var a = 2; a <= AnteScaling.lastEndlessAnte; a++) {
        expect(
          AnteScaling.priceMultiplier(a),
          greaterThan(AnteScaling.priceMultiplier(a - 1)),
          reason: 'ante $a',
        );
      }
      expect(AnteScaling.priceMultiplier(0), 1.0);
    });
  });

  group('ShopPricing.price', () {
    test('Ante 1 prices are the base prices', () {
      for (final base in [5, 6, 7, 9, 12, 14, 22, 28]) {
        expect(ShopPricing.price(base, ante: 1), base);
      }
    });

    test('Ante 4 examples (x1.45), rounded to whole dollars', () {
      expect(ShopPricing.price(6, ante: 4), 9); // 8.7
      expect(ShopPricing.price(7, ante: 4), 10); // 10.15
      expect(ShopPricing.price(14, ante: 4), 20); // 20.3
      expect(ShopPricing.price(16, ante: 4), 23); // 23.2
      expect(ShopPricing.price(22, ante: 4), 32); // 31.9
      expect(ShopPricing.price(12, ante: 4), 17); // 17.4
    });

    test('Ante 8 examples (x2.05)', () {
      expect(ShopPricing.price(6, ante: 8), 12); // 12.3
      expect(ShopPricing.price(16, ante: 8), 33); // 32.8
      expect(ShopPricing.price(22, ante: 8), 45); // 45.1
      expect(ShopPricing.price(12, ante: 8), 25); // 24.6
    });

    test('a voucher discount applies after inflation', () {
      expect(ShopPricing.price(12, ante: 1, discount: 0.25), 9);
      expect(ShopPricing.price(20, ante: 4, discount: 0.25), 22); // 21.75
    });

    test('never below \$1', () {
      expect(ShopPricing.price(1, ante: 1, discount: 0.9), 1);
    });
  });

  group('reroll cost', () {
    test('starts at \$5 and rises \$2 per consecutive reroll', () {
      expect(
        [for (var i = 0; i < 6; i++) ShopPricing.rerollCost(i)],
        [5, 7, 9, 11, 13, 15],
      );
    });

    test('is not inflated by the Ante or discounted by vouchers', () {
      // There is no ante/discount parameter at all: the cost only depends on
      // how many rerolls were done this visit.
      expect(ShopGenerator.rerollCost(0), 5);
      expect(ShopGenerator.rerollCost(2), 9);
    });
  });

  group('base price table', () {
    test('every joker is priced inside its rarity range', () {
      for (final d in JokerRegistry.all) {
        expect(
          d.basePrice,
          inInclusiveRange(d.rarity.minPrice, d.rarity.maxPrice),
          reason: '${d.name} (${d.rarity.name})',
        );
      }
    });

    test(
      'the ranges are Common 6-7, Uncommon 9-11, Rare 14-16, Legendary 22+',
      () {
        expect(
          [JokerRarity.common.minPrice, JokerRarity.common.maxPrice],
          [6, 7],
        );
        expect(
          [JokerRarity.uncommon.minPrice, JokerRarity.uncommon.maxPrice],
          [9, 11],
        );
        expect(
          [JokerRarity.rare.minPrice, JokerRarity.rare.maxPrice],
          [14, 16],
        );
        expect(JokerRarity.legendary.minPrice, 22);
      },
    );

    test('each tier has jokers, and Legendary starts at \$22', () {
      for (final r in JokerRarity.values) {
        expect(JokerRegistry.all.where((d) => d.rarity == r), isNotEmpty);
      }
      for (final d in JokerRegistry.all.where(
        (d) => d.rarity == JokerRarity.legendary,
      )) {
        expect(d.basePrice, greaterThanOrEqualTo(22));
      }
    });

    test('Blueprint cards are \$5, Chisel cards are \$6', () {
      for (final c in ConsumableRegistry.all) {
        expect(c.basePrice, c is BlueprintCard ? 5 : 6, reason: c.id);
      }
    });

    test('every voucher is \$12', () {
      expect(Voucher.basePrice, 12);
      expect(VoucherRegistry.all.length, 4);
      expect(VoucherRegistry.all.map((v) => v.id).toSet().length, 4);
    });

    test('selling returns half the BASE price, whatever the Ante', () {
      for (final d in JokerRegistry.all) {
        expect(d.sellValue, d.basePrice ~/ 2);
      }
      expect(JokerRegistry.byId('joker_singularity').sellValue, 12);
    });
  });
}
