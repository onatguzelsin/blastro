import 'package:flutter/material.dart';

import '../core/roguelite/consumables.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';

/// One purchasable shop card.
class ShopItemTile extends StatelessWidget {
  const ShopItemTile({
    super.key,
    required this.item,
    required this.result,
    required this.onBuy,
  });

  final ShopItem item;

  /// Whether the player can buy it right now (drives the button label).
  final BuyResult result;
  final VoidCallback onBuy;

  static String nameOf(ShopItem i) => i.isJoker
      ? JokerRegistry.byId(i.id).name
      : ConsumableRegistry.byId(i.id).name;

  static String descriptionOf(ShopItem i) => i.isJoker
      ? JokerRegistry.byId(i.id).description
      : ConsumableRegistry.byId(i.id).description;

  static String buttonLabel(ShopItem i, BuyResult r) => switch (r) {
    BuyResult.ok => 'Buy \$${i.price}',
    BuyResult.tooExpensive => '\$${i.price}',
    BuyResult.noSlot => 'Full',
    BuyResult.alreadyOwned => 'Owned',
  };

  @override
  Widget build(BuildContext context) {
    final color = item.isJoker
        ? const Color(0xFFB388FF)
        : const Color(0xFF40C4FF);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nameOf(item),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            descriptionOf(item),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: result == BuyResult.ok ? onBuy : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(34),
              padding: EdgeInsets.zero,
            ),
            child: Text(buttonLabel(item, result)),
          ),
        ],
      ),
    );
  }
}
