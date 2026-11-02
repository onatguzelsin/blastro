import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/ui/rarity_badge.dart';
import 'package:blastro/ui/rarity_frame.dart';
import 'package:blastro/ui/rarity_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _purple = Color(0xFFA855F7);
const _gold = Color(0xFFF59E0B);

BoxDecoration _outer(WidgetTester t, Finder frame) =>
    t
            .widget<Container>(
              find
                  .descendant(of: frame, matching: find.byType(Container))
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  group('the palette', () {
    test('exact colours and labels', () {
      expect(RarityStyle.common.color, const Color(0xFF3B82F6));
      expect(RarityStyle.uncommon.color, const Color(0xFF10B981));
      expect(RarityStyle.rare.color, const Color(0xFFEF4444));
      expect(RarityStyle.legendary.color, _purple);
      expect(RarityStyle.legendary.secondary, _gold);
      expect(
        [for (final r in JokerRarity.values) RarityStyle.ofRarity(r).label],
        ['COMMON', 'UNCOMMON', 'RARE', 'LEGENDARY'],
      );
    });

    test('only Legendary is a gradient', () {
      expect(RarityStyle.legendary.isGradient, isTrue);
      for (final s in [
        RarityStyle.common,
        RarityStyle.uncommon,
        RarityStyle.rare,
      ]) {
        expect(s.isGradient, isFalse);
        expect(s.gradient.colors, [s.color, s.color]);
      }
      expect(RarityStyle.legendary.gradient.colors, [_purple, _gold]);
    });

    test('each background tint leans toward its own colour', () {
      final c = RarityStyle.common.background();
      final u = RarityStyle.uncommon.background();
      final r = RarityStyle.rare.background();
      final l = RarityStyle.legendary.background();
      expect(c.b, greaterThan(c.r));
      expect(c.b, greaterThan(c.g));
      expect(u.g, greaterThan(u.r));
      expect(u.g, greaterThan(u.b));
      expect(r.r, greaterThan(r.g));
      expect(r.r, greaterThan(r.b));
      expect(l.b, greaterThan(l.g));
      expect(l.r, greaterThan(l.g));
      expect({c, u, r, l}.length, 4);
    });

    test('non-joker items have their own colours', () {
      expect(RarityStyle.voucher.label, 'VOUCHER');
      expect(RarityStyle.blueprint.label, 'BLUEPRINT');
      expect(RarityStyle.chisel.label, 'CHISEL');
      expect(
        RarityStyle.ofItem(
          const ShopItem(
            id: 'voucher_overstock',
            kind: ShopItemKind.voucher,
            price: 12,
          ),
        ),
        RarityStyle.voucher,
      );
      expect(
        RarityStyle.ofItem(
          const ShopItem(
            id: 'blueprint_quad',
            kind: ShopItemKind.consumable,
            price: 5,
          ),
        ),
        RarityStyle.blueprint,
      );
      expect(
        RarityStyle.ofItem(
          const ShopItem(
            id: 'chisel_steel',
            kind: ShopItemKind.consumable,
            price: 6,
          ),
        ),
        RarityStyle.chisel,
      );
    });
  });

  group('badge and frame widgets', () {
    testWidgets('the pill names the rarity; Legendary is filled purple-gold', (
      t,
    ) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Column(
              children: [
                RarityBadge(style: RarityStyle.common),
                RarityBadge(style: RarityStyle.legendary),
              ],
            ),
          ),
        ),
      );
      expect(find.text('COMMON'), findsOneWidget);
      expect(find.text('LEGENDARY'), findsOneWidget);
      final legendary = t.widget<Container>(
        find
            .ancestor(
              of: find.text('LEGENDARY'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (legendary.decoration! as BoxDecoration).gradient,
        RarityStyle.legendary.gradient,
      );
    });

    testWidgets('the frame has a glowing border in the rarity colour', (
      t,
    ) async {
      for (final style in [
        RarityStyle.common,
        RarityStyle.uncommon,
        RarityStyle.rare,
        RarityStyle.legendary,
      ]) {
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: RarityFrame(style: style, child: const SizedBox(width: 50)),
            ),
          ),
        );
        final outer = _outer(t, find.byType(RarityFrame));
        expect(outer.gradient, style.gradient, reason: style.label);
        expect(outer.boxShadow, isNotEmpty);
        expect(outer.boxShadow!.first.color, style.glow);
        expect(outer.boxShadow!.first.blurRadius, greaterThan(4));
      }
    });
  });
}
