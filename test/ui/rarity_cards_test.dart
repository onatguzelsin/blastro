import 'package:blastro/core/roguelite/joker_effects.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/joker_reorder_bar.dart';
import 'package:blastro/ui/purchase_dialog.dart';
import 'package:blastro/ui/rarity_frame.dart';
import 'package:blastro/ui/rarity_style.dart';
import 'package:blastro/ui/shop_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _purple = Color(0xFFA855F7);

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget child,
  RunState Function(RunState) setup,
) async {
  await t.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  n.debugSet(setup(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

Joker _joker(String id) => JokerRegistry.byId(id).joker;

List<RarityStyle> _styles(WidgetTester t, Finder within) => t
    .widgetList<RarityFrame>(
      find.descendant(of: within, matching: find.byType(RarityFrame)),
    )
    .map((f) => f.style)
    .toList();

void main() {
  group('the 5-slot joker bar', () {
    RunState four(RunState s) => s.copyWith(
      jokers: [
        _joker('joker_plain'),
        _joker('joker_amplifier'),
        _joker('joker_3x3_sanctuary'),
        _joker('joker_singularity'),
      ],
    );

    testWidgets('each joker is framed in its own rarity, with a pill', (
      t,
    ) async {
      await _pump(t, const JokerReorderBar(), four);
      expect(_styles(t, find.byType(JokerReorderBar)), [
        RarityStyle.common,
        RarityStyle.uncommon,
        RarityStyle.rare,
        RarityStyle.legendary,
      ]);
      for (final label in ['COMMON', 'UNCOMMON', 'RARE', 'LEGENDARY']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('an unknown joker falls back to the Common look', (t) async {
      expect(
        JokerCard.styleOf(const Joker(id: 'joker_from_the_future')),
        RarityStyle.common,
      );
    });

    testWidgets('a debuffed joker keeps its rarity frame under the red cross', (
      t,
    ) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 90,
                height: 80,
                child: JokerCard(
                  joker: _joker('joker_singularity'),
                  debuffed: true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(_styles(t, find.byType(JokerCard)), [RarityStyle.legendary]);
    });

    testWidgets('tapping a joker inspects it: effect, rarity, sell value', (
      t,
    ) async {
      await _pump(t, const JokerReorderBar(), four);
      await t.tap(find.text('Singularity'));
      await t.pumpAndSettle();
      expect(find.text('x3 Mult on every scoring move.'), findsOneWidget);
      expect(find.text('LEGENDARY'), findsNWidgets(2), reason: 'bar + dialog');
      expect(find.text('Sells for \$12'), findsOneWidget);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      expect(find.text('Sells for \$12'), findsNothing);
    });
  });

  group('shop and confirmation', () {
    RunState stocked(RunState s) => s.copyWith(
      status: RunStatus.shopping,
      gold: 100,
      shop: const ShopState(
        stock: [
          ShopItem(id: 'joker_plain', kind: ShopItemKind.joker, price: 6),
          ShopItem(id: 'joker_heavyweight', kind: ShopItemKind.joker, price: 9),
          ShopItem(id: 'joker_mime', kind: ShopItemKind.joker, price: 9),
          ShopItem(
            id: 'joker_singularity',
            kind: ShopItemKind.joker,
            price: 25,
          ),
          ShopItem(
            id: 'voucher_wasteful',
            kind: ShopItemKind.voucher,
            price: 12,
          ),
          ShopItem(
            id: 'blueprint_quad',
            kind: ShopItemKind.consumable,
            price: 5,
          ),
          ShopItem(id: 'chisel_steel', kind: ShopItemKind.consumable, price: 6),
        ],
      ),
    );

    testWidgets('every shop tile is framed by rarity or item kind', (t) async {
      await _pump(t, const ShopSheet(), stocked);
      final styles = _styles(t, find.byType(ShopSheet)).map((s) => s.label);
      expect(
        styles,
        containsAll([
          'COMMON',
          'UNCOMMON',
          'LEGENDARY',
          'VOUCHER',
          'BLUEPRINT',
          'CHISEL',
        ]),
      );
    });

    testWidgets('the confirmation dialog wears the item\'s rarity', (t) async {
      await _pump(t, const ShopSheet(), stocked);
      await t.tap(find.text('Singularity'));
      await t.pumpAndSettle();
      expect(_styles(t, find.byType(PurchaseDialog)), [RarityStyle.legendary]);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Heavyweight'));
      await t.pumpAndSettle();
      expect(_styles(t, find.byType(PurchaseDialog)), [RarityStyle.uncommon]);
    });

    testWidgets('sell chips are outlined in the joker\'s rarity colour', (
      t,
    ) async {
      await _pump(
        t,
        const ShopSheet(),
        (s) => stocked(s).copyWith(jokers: [_joker('joker_singularity')]),
      );
      final chip = t.widget<ActionChip>(find.byType(ActionChip));
      expect(chip.side!.color, _purple);
    });
  });
}
