import 'package:flutter/material.dart';

import '../core/roguelite/consumables.dart';
import '../core/roguelite/joker_registry.dart';
import '../core/roguelite/shop_generator.dart';

/// The color theme of a joker rarity (or a non-joker item kind): pill label,
/// border/glow color and, for Legendary, a second color for the gradient.
class RarityStyle {
  const RarityStyle({required this.label, required this.color, this.secondary});

  final String label;
  final Color color;

  /// Set only for Legendary (purple to gold).
  final Color? secondary;

  static const common = RarityStyle(label: 'COMMON', color: Color(0xFF3B82F6));
  static const uncommon = RarityStyle(
    label: 'UNCOMMON',
    color: Color(0xFF10B981),
  );
  static const rare = RarityStyle(label: 'RARE', color: Color(0xFFEF4444));
  static const legendary = RarityStyle(
    label: 'LEGENDARY',
    color: Color(0xFFA855F7),
    secondary: Color(0xFFF59E0B),
  );

  // Non-joker items, colored by kind.
  static const blueprint = RarityStyle(
    label: 'BLUEPRINT',
    color: Color(0xFF38BDF8),
  );
  static const chisel = RarityStyle(label: 'CHISEL', color: Color(0xFFF97316));
  static const voucher = RarityStyle(
    label: 'VOUCHER',
    color: Color(0xFF14B8A6),
  );

  static RarityStyle ofRarity(JokerRarity r) => switch (r) {
    JokerRarity.common => common,
    JokerRarity.uncommon => uncommon,
    JokerRarity.rare => rare,
    JokerRarity.legendary => legendary,
  };

  /// The style for a shop item: rarity for jokers, kind for the rest.
  static RarityStyle ofItem(ShopItem item) => switch (item.kind) {
    ShopItemKind.joker => ofRarity(JokerRegistry.byId(item.id).rarity),
    ShopItemKind.voucher => voucher,
    ShopItemKind.consumable =>
      ConsumableRegistry.byId(item.id) is BlueprintCard ? blueprint : chisel,
  };

  bool get isGradient => secondary != null;

  /// Border and pill fill: the two colors for Legendary, else solid.
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, secondary ?? color],
  );

  Color get glow => color.withValues(alpha: 0.55);

  /// The card background: the style color faintly tinted over the dark base.
  ///
  /// The base is a neutral dark grey (not the app's blue-ish navy), so an
  /// emerald tint reads green and not teal.
  Color background([double strength = 0.26]) => Color.alphaBlend(
    color.withValues(alpha: strength),
    const Color(0xFF14171F),
  );
}
