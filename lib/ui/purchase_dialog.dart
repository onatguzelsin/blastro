import 'package:flutter/material.dart';

import '../core/roguelite/shop_generator.dart';
import 'rarity_badge.dart';
import 'rarity_frame.dart';
import 'shop_item_info.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_menu.dart';
import '../core/i18n/supported_language.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// Asks "Are you sure?" before anything is bought. Resolves to true only when
/// the player taps Confirm Purchase.
Future<bool> showPurchaseDialog(
  BuildContext context, {
  required ShopItem item,
  required int gold,
  required BuyResult result,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) =>
        PurchaseDialog(item: item, gold: gold, result: result),
  );
  return confirmed ?? false;
}

class PurchaseDialog extends ConsumerWidget {
  const PurchaseDialog({
    super.key,
    required this.item,
    required this.gold,
    required this.result,
  });

  final ShopItem item;

  /// The bankroll right now.
  final int gold;
  final BuyResult result;

  /// Why the purchase is blocked, or null when it can go ahead.
  static String? blockedReason(
    ShopItem item,
    int gold,
    BuyResult r, [
    AppStrings? strings,
  ]) {
    final s = strings ?? AppStrings(Languages.english);
    return switch (r) {
      BuyResult.ok => null,
      BuyResult.tooExpensive => s.t(FlowStr.buyBroke, {'n': item.price - gold}),
      BuyResult.noSlot => s.t(
        item.isJoker ? FlowStr.buyJokerFull : FlowStr.buyCardFull,
      ),
      BuyResult.alreadyOwned => s.t(FlowStr.buyOwned),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final info = ShopItemInfo.of(item, strings);
    final remaining = gold - item.price;
    final reason = blockedReason(item, gold, result, strings);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: RarityFrame(
          style: info.style,
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RarityBadge(style: info.style),
                  const Spacer(),
                  Text(
                    '\$${item.price}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t(FlowStr.buyAsk, {'name': info.name, 'n': item.price}),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                info.description,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
              const Divider(height: 24),
              _moneyRow(t(FlowStr.buyBankroll), '\$$gold', Colors.white),
              _moneyRow(
                t(FlowStr.buyAfter),
                '\$$remaining',
                remaining >= 0
                    ? const Color(0xFF69F0AE)
                    : const Color(0xFFFF5252),
              ),
              if (reason != null) ...[
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(t(MenuStr.cancel)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: reason == null
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Text(t(FlowStr.buyConfirm)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moneyRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );
}
