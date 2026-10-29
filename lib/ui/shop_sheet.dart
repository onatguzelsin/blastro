import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';
import '../state/run_notifier.dart';
import 'consumable_row.dart';
import 'shop_item_tile.dart';
import 'slide_up_sheet.dart';

/// Mobile shop: buy jokers and consumables, reroll, sell, then advance.
class ShopSheet extends ConsumerWidget {
  const ShopSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    final notifier = ref.read(runProvider.notifier);
    final stock = s.shop?.stock ?? const <ShopItem>[];
    final rerollCost = ShopGenerator.rerollCost(s.shop?.rerolls ?? 0);
    final owned = {for (final j in s.jokers) j.id};

    Widget tiles(bool jokers) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in stock.where((i) => i.isJoker == jokers))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ShopItemTile(
                item: item,
                result: ShopGenerator.canBuy(
                  item,
                  gold: s.gold,
                  jokerCount: s.jokers.length,
                  consumableCount: s.consumables.length,
                  ownedJokerIds: owned,
                ),
                onBuy: () => notifier.buyItem(item.id),
              ),
            ),
          ),
      ],
    );

    return SlideUpSheet(
      title: 'Shop',
      trailing: Text(
        '\$${s.gold}',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFD54F),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('Jokers'),
          tiles(true),
          _heading('Cards'),
          tiles(false),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: s.gold >= rerollCost ? notifier.rerollShop : null,
              child: Text('Reroll  \$$rerollCost'),
            ),
          ),
          _heading('Your jokers (${s.jokers.length}/5)'),
          if (s.jokers.isEmpty)
            const Text('None yet', style: TextStyle(color: Colors.white38)),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < s.jokers.length; i++)
                ActionChip(
                  label: Text(
                    'Sell ${JokerRegistry.byId(s.jokers[i].id).name} '
                    '+\$${JokerRegistry.byId(s.jokers[i].id).sellValue}',
                  ),
                  onPressed: () => notifier.sellJoker(i),
                ),
            ],
          ),
          _heading('Your cards'),
          const ConsumableRow(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: notifier.leaveShop,
              child: const Text('Next Blind'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.white60,
      ),
    ),
  );
}
