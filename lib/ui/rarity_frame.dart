import 'package:flutter/material.dart';

import 'rarity_style.dart';

/// A card frame in a rarity's colors: a tinted background, a glowing border
/// and, for Legendary, a purple-to-gold gradient border.
class RarityFrame extends StatelessWidget {
  const RarityFrame({
    super.key,
    required this.style,
    required this.child,
    this.radius = 10,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.all(8),
  });

  final RarityStyle style;
  final Widget child;
  final double radius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The outer box is the border (a gradient for Legendary) plus the glow.
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        gradient: style.gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: style.glow, blurRadius: 10, spreadRadius: 0.5),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: style.background(),
          borderRadius: BorderRadius.circular(radius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}
