import 'package:flutter/material.dart';

import '../core/roguelite/shop_generator.dart';
import 'rarity_badge.dart';
import 'rarity_frame.dart';
import 'shop_item_info.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/supported_language.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// One item for sale. Tapping it opens the purchase confirmation; there is no
/// one-tap buy. The price is red when you cannot afford it.
class ShopItemTile extends ConsumerWidget {
  const ShopItemTile({
    super.key,
    required this.item,
    required this.result,
    required this.onTap,
  });

  final ShopItem item;

  /// Whether the player could buy it right now (drives the price styling).
  final BuyResult result;
  final VoidCallback onTap;

  static String statusLabel(ShopItem item, BuyResult r, [AppStrings? s]) {
    final strings = s ?? AppStrings(Languages.english);
    return switch (r) {
      BuyResult.ok || BuyResult.tooExpensive => '\$${item.price}',
      BuyResult.noSlot => strings.t(FlowStr.noSlot),
      BuyResult.alreadyOwned => strings.t(FlowStr.owned),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final info = ShopItemInfo.of(item, strings);
    final affordable = result == BuyResult.ok;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: affordable ? 1 : 0.78,
        child: RarityFrame(
          style: info.style,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RarityBadge(style: info.style),
              const SizedBox(height: 6),
              Text(
                info.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.description,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel(item, result, strings),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: switch (result) {
                    BuyResult.ok => const Color(0xFFFFD54F),
                    BuyResult.tooExpensive => const Color(0xFFFF5252),
                    _ => Colors.white54,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
