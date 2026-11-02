/// A translated name and description for one joker, card, voucher, boss or
/// deck. [short] is the joker card's one-liner.
class ContentText {
  const ContentText(this.name, this.description, [this.short]);

  final String name;
  final String description;
  final String? short;
}
