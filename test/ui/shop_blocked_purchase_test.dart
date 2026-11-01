import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
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
  group('items you cannot buy', () {
    testWidgets('too expensive: the dialog opens, Confirm is disabled', (
      t,
    ) async {
      final c = await _pump(t, setup: (s) => _shopping(s, gold: 2));
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      expect(find.text('Not enough money: you need \$4 more.'), findsOneWidget);
      final confirm = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Purchase'),
      );
      expect(confirm.onPressed, isNull);
      await t.tap(find.text('Confirm Purchase'), warnIfMissed: false);
      expect(c.read(runProvider).jokers, isEmpty);
    });

    testWidgets('the shop price turns red when you are short', (t) async {
      await _pump(t, setup: (s) => _shopping(s, gold: 2));
      final price = t.widget<Text>(find.text('\$6').first);
      expect(price.style!.color, const Color(0xFFFF5252));
    });

    testWidgets('full joker slots are explained', (t) async {
      await _pump(
        t,
        setup: (s) => _shopping(s, gold: 99).copyWith(
          jokers: [for (final d in JokerRegistry.all.skip(10).take(5)) d.joker],
        ),
      );
      await t.tap(find.text('Plain Joker'));
      await t.pumpAndSettle();
      expect(
        find.text('Your joker slots are full. Sell a joker first.'),
        findsOneWidget,
      );
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm Purchase'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an owned voucher says so', (t) async {
      await _pump(
        t,
        setup: (s) => _shopping(s).copyWith(vouchers: ['voucher_overstock']),
      );
      await t.tap(find.text('Overstock').first);
      await t.pumpAndSettle();
      expect(find.text('You already own this.'), findsOneWidget);
    });
  });

  group('the rest of the shop', () {
    testWidgets('reroll goes \$5 then \$7', (t) async {
      final c = await _pump(t, setup: (s) => _shopping(s, gold: 50));
      expect(find.text('Reroll  \$5'), findsOneWidget);
      await t.ensureVisible(find.text('Reroll  \$5'));
      await t.tap(find.text('Reroll  \$5'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).gold, 45);
      expect(find.text('Reroll  \$7'), findsOneWidget);
      await t.ensureVisible(find.text('Reroll  \$7'));
      await t.tap(find.text('Reroll  \$7'));
      await t.pumpAndSettle();
      expect(c.read(runProvider).gold, 38);
      expect(find.text('Reroll  \$9'), findsOneWidget);
    });

    testWidgets('Next Blind leads to Blind Select', (t) async {
      final c = await _pump(t);
      await t.ensureVisible(find.text('Next Blind'));
      await t.tap(find.text('Next Blind'));
      await t.pump();
      expect(c.read(runProvider).status, RunStatus.blindSelect);
    });

    testWidgets('sells a joker and uses a held card', (t) async {
      final c = await _pump(
        t,
        setup: (s) => _shopping(s).copyWith(
          jokers: [JokerRegistry.byId('joker_plain').joker],
          consumables: ['blueprint_single'],
        ),
      );
      await t.ensureVisible(find.text('Use'));
      await t.tap(find.text('Use'));
      await t.pump();
      expect(c.read(runProvider).consumables, isEmpty);
      await t.tap(find.text('Sell Plain Joker +\$3'));
      await t.pump();
      expect(c.read(runProvider).jokers, isEmpty);
      expect(c.read(runProvider).gold, 23);
    });

    testWidgets('lists the vouchers you own', (t) async {
      await _pump(
        t,
        setup: (s) =>
            _shopping(s)
                .copyWith(vouchers: ['voucher_wasteful', 'voucher_seed_money']),
      );
      expect(find.text('Wasteful · Seed Money'), findsOneWidget);
    });
  });
}
