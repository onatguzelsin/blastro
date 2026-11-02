import '../core/roguelite/consumables.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';
import '../core/roguelite/vouchers.dart';
import 'rarity_style.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/supported_language.dart';

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

  /// [strings] translates the name and description (English if omitted).
  factory ShopItemInfo.of(ShopItem item, [AppStrings? strings]) {
    final s = strings ?? AppStrings(Languages.english);
    return switch (item.kind) {
      ShopItemKind.joker => () {
        final def = JokerRegistry.byId(item.id);
        return ShopItemInfo(
          name: s.nameOf(def.id, def.name),
          description: s.descriptionOf(def.id, def.description),
          style: RarityStyle.ofRarity(def.rarity),
        );
      }(),
      ShopItemKind.consumable => () {
        final card = ConsumableRegistry.byId(item.id);
        return ShopItemInfo(
          name: s.nameOf(card.id, card.name),
          description: s.descriptionOf(card.id, card.description),
          style: RarityStyle.ofItem(item),
        );
      }(),
      ShopItemKind.voucher => () {
        final v = VoucherRegistry.byId(item.id);
        return ShopItemInfo(
          name: s.nameOf(v.id, v.name),
          description: s.descriptionOf(v.id, v.description),
          style: RarityStyle.voucher,
        );
      }(),
    };
  }
}
