import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';
import '../core/roguelite/vouchers.dart';
import '../state/run_notifier.dart';
import '../state/run_state.dart';
import 'consumable_row.dart';
import 'purchase_dialog.dart';
import 'rarity_style.dart';
import 'shop_item_tile.dart';
import 'slide_up_sheet.dart';

/// Mobile shop: jokers, vouchers and cards for sale, reroll, sell, advance.
/// Tapping an item opens a confirmation; nothing is bought in one tap.
class ShopSheet extends ConsumerWidget {
  const ShopSheet({super.key});

  BuyResult _result(RunState s, ShopItem item) => ShopGenerator.canBuy(
    item,
    gold: s.gold,
    jokerCount: s.jokers.length,
    consumableCount: s.consumables.length,
    ownedJokerIds: {for (final j in s.jokers) j.id},
    ownedVoucherIds: s.vouchers.toSet(),
  );

  Future<void> _confirmBuy(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
  ) async {
    final s = ref.read(runProvider);
    final confirmed = await showPurchaseDialog(
      context,
      item: item,
      gold: s.gold,
      result: _result(s, item),
    );
    if (confirmed) ref.read(runProvider.notifier).buyItem(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    final notifier = ref.read(runProvider.notifier);
    final stock = s.shop?.stock ?? const <ShopItem>[];
    final rerollCost = ShopGenerator.rerollCost(s.shop?.rerolls ?? 0);

    Widget tiles(ShopItemKind kind) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in stock.where((i) => i.kind == kind))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ShopItemTile(
                item: item,
                result: _result(s, item),
                onTap: () => _confirmBuy(context, ref, item),
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
          tiles(ShopItemKind.joker),
          if (stock.any((i) => i.isVoucher)) ...[
            _heading('Voucher (permanent upgrade)'),
            tiles(ShopItemKind.voucher),
          ],
          _heading('Cards'),
          tiles(ShopItemKind.consumable),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: s.gold >= rerollCost ? notifier.rerollShop : null,
              child: Text('Reroll  \$$rerollCost'),
            ),
          ),
          _heading('Your jokers (${s.jokers.length}/${RunState.maxJokers})'),
          if (s.jokers.isEmpty)
            const Text('None yet', style: TextStyle(color: Colors.white38)),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < s.jokers.length; i++)
                _sellChip(notifier, s, i),
            ],
          ),
          if (s.vouchers.isNotEmpty) ...[
            _heading('Your vouchers'),
            Text(
              [for (final id in s.vouchers) VoucherRegistry.byId(id).name]
                  .join(' · '),
              style: const TextStyle(color: Color(0xFF14B8A6)),
            ),
          ],
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

  Widget _sellChip(RunNotifier notifier, RunState s, int i) {
    final def = JokerRegistry.byId(s.jokers[i].id);
    final style = RarityStyle.ofRarity(def.rarity);
    return ActionChip(
      side: BorderSide(color: style.color, width: 1.5),
      backgroundColor: style.background(0.25),
      label: Text('Sell ${def.name} +\$${def.sellValue}'),
      onPressed: () => notifier.sellJoker(i),
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
