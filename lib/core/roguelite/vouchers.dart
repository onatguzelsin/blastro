import 'run_modifiers.dart';

/// A permanent upgrade bought once per run. Its effect is a [RunModifiers].
class Voucher {
  const Voucher({
    required this.id,
    required this.name,
    required this.description,
    required this.modifiers,
  });

  /// Every voucher costs $12 at Ante 1 (then inflates like everything else).
  static const int basePrice = 12;

  final String id;
  final String name;
  final String description;
  final RunModifiers modifiers;
}

abstract final class VoucherRegistry {
  static const overstock = Voucher(
    id: 'voucher_overstock',
    name: 'Overstock',
    description: '+1 joker for sale in every shop.',
    modifiers: RunModifiers(shopJokerSlots: 1),
  );
  static const clearanceSale = Voucher(
    id: 'voucher_clearance_sale',
    name: 'Clearance Sale',
    description: 'Future shops and rerolls are 25% cheaper.',
    modifiers: RunModifiers(priceDiscount: 0.25),
  );
  static const seedMoney = Voucher(
    id: 'voucher_seed_money',
    name: 'Seed Money',
    description: 'Interest at cash out is capped at \$10 instead of \$5.',
    modifiers: RunModifiers(interestCap: 10),
  );
  static const wasteful = Voucher(
    id: 'voucher_wasteful',
    name: 'Wasteful',
    description: '+1 discard every blind.',
    modifiers: RunModifiers(extraDiscards: 1),
  );

  static const List<Voucher> all = [
    overstock,
    clearanceSale,
    seedMoney,
    wasteful,
  ];

  static Voucher? maybeById(String id) {
    for (final v in all) {
      if (v.id == id) return v;
    }
    return null;
  }

  static Voucher byId(String id) {
    final v = maybeById(id);
    if (v == null) throw ArgumentError('Unknown voucher: $id');
    return v;
  }
}
