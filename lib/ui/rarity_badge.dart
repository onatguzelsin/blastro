import 'package:flutter/material.dart';

import 'rarity_style.dart';

/// The small rounded pill naming a rarity (`COMMON`, `LEGENDARY`, ...).
/// Legendary's pill is filled with the purple-to-gold gradient.
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.style, this.small = false});

  final RarityStyle style;

  /// A tiny version for the joker bar cards.
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 8,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        gradient: style.gradient,
        borderRadius: BorderRadius.circular(small ? 4 : 10),
      ),
      child: Text(
        style.label,
        maxLines: 1,
        style: TextStyle(
          fontSize: small ? 7 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: small ? 0.3 : 0.8,
          color: Colors.white,
        ),
      ),
    );
  }
}
