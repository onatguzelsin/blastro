import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/purchase_dialog.dart';
import 'package:blastro/ui/shop_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _joker = ShopItem(id: 'joker_plain', kind: ShopItemKind.joker, price: 6);
const _card = ShopItem(
  id: 'chisel_bonus',
  kind: ShopItemKind.consumable,
  price: 6,
);
const _voucher = ShopItem(
  id: 'voucher_overstock',
  kind: ShopItemKind.voucher,
  price: 12,
);
const _legend = ShopItem(
  id: 'joker_singularity',
  kind: ShopItemKind.joker,
  price: 25,
);

RunState _shopping(RunState s, {int gold = 20, List<ShopItem>? stock}) =>
    s.copyWith(
      status: RunStatus.shopping,
      gold: gold,
      shop: ShopState(stock: stock ?? const [_joker, _voucher, _card]),
    );

Future<ProviderContainer> _pump(
  WidgetTester t, {
  RunState Function(RunState)? setup,
}) async {
  await t.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  n.debugSet((setup ?? _shopping)(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: ShopSheet())),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

void main() {
  group('no one-tap purchases', () {
    testWidgets('the shop has no Buy buttons any more', (t) async {
      await _pump(t);
      expect(find.textContaining('Buy'), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget, reason: 'Next Blind');
    });

    testWidgets('tapping a joker opens a confirmation and buys nothing', (
      t,
    ) async {
      final c = await _pump(t);
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      expect(find.byType(PurchaseDialog), findsOneWidget);
      expect(
        find.text('Are you sure you want to buy Plain Joker for \$6?'),
        findsOneWidget,
      );
      expect(c.read(runProvider).jokers, isEmpty);
      expect(c.read(runProvider).gold, 20);
    });

    testWidgets('Cancel closes it with nothing bought', (t) async {
      final c = await _pump(t);
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.byType(PurchaseDialog), findsNothing);
      expect(c.read(runProvider).jokers, isEmpty);
      expect(c.read(runProvider).gold, 20);
    });

    testWidgets('tapping outside the dialog also cancels', (t) async {
      final c = await _pump(t);
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(find.byType(PurchaseDialog), findsNothing);
      expect(c.read(runProvider).jokers, isEmpty);
    });

    testWidgets('Confirm Purchase buys it, once', (t) async {
      final c = await _pump(t);
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirm Purchase'));
      await t.pumpAndSettle();
      expect(find.byType(PurchaseDialog), findsNothing);
      expect(c.read(runProvider).jokers.single.id, 'joker_plain');
      expect(c.read(runProvider).gold, 14);
      expect(find.text('Sell Plain Joker +\$3'), findsOneWidget);
    });

    testWidgets('cards and vouchers need confirming too', (t) async {
      final c = await _pump(t);
      await t.tap(find.text('Chisel: Bonus'));
      await t.pumpAndSettle();
      expect(find.byType(PurchaseDialog), findsOneWidget);
      expect(c.read(runProvider).consumables, isEmpty);
      await t.tap(find.text('Confirm Purchase'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).consumables, ['chisel_bonus']);

      await t.tap(find.text('Overstock'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).vouchers, isEmpty);
      await t.tap(find.text('Confirm Purchase'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).vouchers, ['voucher_overstock']);
      expect(c.read(runProvider).gold, 2, reason: '20 - 6 - 12');
    });
  });

  group('what the confirmation shows', () {
    testWidgets('full description, rarity badge and bankroll before/after', (
      t,
    ) async {
      await _pump(t);
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      expect(find.text('+4 Mult on every scoring move.'), findsWidgets);
      expect(find.text('COMMON'), findsWidgets);
      expect(find.text('Your bankroll'), findsOneWidget);
      final dialog = find.byType(PurchaseDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('\$20')),
        findsOneWidget,
      );
      expect(find.text('After purchase'), findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('\$14')),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Purchase'), findsOneWidget);
    });

    testWidgets('shows the remaining money in green, the effect in full', (
      t,
    ) async {
      await _pump(t, setup: (s) => _shopping(s, stock: const [_legend]));
      await t.tap(find.text('Singularity'));
      await t.pumpAndSettle();
      expect(find.text('LEGENDARY'), findsWidgets);
      expect(find.text('x3 Mult on every scoring move.'), findsWidgets);
      final after = t.widget<Text>(find.text('\$-5'));
      expect(
        after.style!.color,
        const Color(0xFFFF5252),
        reason: 'short of cash',
      );
    });

    testWidgets('voucher and card dialogs carry their own badge and text', (
      t,
    ) async {
      await _pump(t);
      await t.tap(find.text('Overstock'));
      await t.pumpAndSettle();
      expect(find.text('VOUCHER'), findsWidgets);
      expect(find.text('+1 joker for sale in every shop.'), findsWidgets);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Chisel: Bonus'));
      await t.pumpAndSettle();
      expect(find.text('CHISEL'), findsWidgets);
      expect(find.text('Make 2 random cells Bonus (+30 Chips).'), findsWidgets);
    });
  });
}
