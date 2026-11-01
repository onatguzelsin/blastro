import '../core/roguelite/consumables.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';
import '../core/roguelite/vouchers.dart';
import 'rarity_style.dart';

/// Display data for one shop item, whatever its kind.
class ShopItemInfo {
  const ShopItemInfo({
    required this.name,
    required this.description,
    required this.style,
  });

  final String name;

  /// The full effect text.
  final String description;
  final RarityStyle style;

  factory ShopItemInfo.of(ShopItem item) => switch (item.kind) {
    ShopItemKind.joker => () {
      final def = JokerRegistry.byId(item.id);
      return ShopItemInfo(
        name: def.name,
        description: def.description,
        style: RarityStyle.ofRarity(def.rarity),
      );
    }(),
    ShopItemKind.consumable => () {
      final card = ConsumableRegistry.byId(item.id);
      return ShopItemInfo(
        name: card.name,
        description: card.description,
        style: RarityStyle.ofItem(item),
      );
    }(),
    ShopItemKind.voucher => () {
      final v = VoucherRegistry.byId(item.id);
      return ShopItemInfo(
        name: v.name,
        description: v.description,
        style: RarityStyle.voucher,
      );
    }(),
  };
}
