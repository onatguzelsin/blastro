/// The color a block is dealt in. Colors are cosmetic until a color-synergy
/// joker reads them (Red Rush, Blue Tide); starter decks pick which colors
/// can appear.
enum BlockColor {
  red,
  blue,
  green,
  yellow;

  String get label => switch (this) {
    BlockColor.red => 'Red',
    BlockColor.blue => 'Blue',
    BlockColor.green => 'Green',
    BlockColor.yellow => 'Yellow',
  };
}
