import 'package:flutter/painting.dart';

import '../core/polyomino/block_color.dart';

/// The look of each block color: a light top and a deeper bottom for the
/// gradient, and the edge color used on enhanced cells.
class BlockShade {
  const BlockShade(this.light, this.dark, this.frame);

  final Color light;
  final Color dark;
  final Color frame;
}

abstract final class BlockPalette {
  /// An uncolored cell (made without a color) looks Blue, as blocks always did.
  static const BlockShade blue = BlockShade(
    Color(0xFF7BA2FF),
    Color(0xFF4A78F0),
    Color(0x55233A8C),
  );
  static const BlockShade red = BlockShade(
    Color(0xFFFF8A80),
    Color(0xFFE53935),
    Color(0x558C1C1C),
  );
  static const BlockShade green = BlockShade(
    Color(0xFF86E39A),
    Color(0xFF2FA84F),
    Color(0x551B5E2F),
  );
  static const BlockShade yellow = BlockShade(
    Color(0xFFFFE680),
    Color(0xFFF2B91F),
    Color(0x55805E00),
  );

  static BlockShade of(BlockColor? color) => switch (color) {
    BlockColor.red => red,
    BlockColor.green => green,
    BlockColor.yellow => yellow,
    BlockColor.blue || null => blue,
  };
}
