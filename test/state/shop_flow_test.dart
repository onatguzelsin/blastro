import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(runProvider.notifier).newRun(11);
  return c;
}

/// A run sitting at the cash-out screen.
RunNotifier _cleared(ProviderContainer c, {int gold = 10, int trays = 4}) {
  final n = c.read(runProvider.notifier);
  n.debugSet(
    c
        .read(runProvider)
        .copyWith(
          status: RunStatus.blindCleared,
          gold: gold,
          traysRemaining: trays,
        ),
  );
  return n;
}

RunNotifier _shop(ProviderContainer c, {int gold = 30}) {
  final n = _cleared(c, gold: gold);
  n.collectCashOut();
  n.debugSet(c.read(runProvider).copyWith(gold: gold));
  return n;
}

void main() {
  test('cash out pays reward + unused trays + interest, then opens a shop', () {
    final c = _container();
    _cleared(c).collectCashOut();
    final s = c.read(runProvider);
    expect(s.gold, 10 + 4 + 3 + 2);
    expect(s.status, RunStatus.shopping);
    expect(s.shop!.stock.length, 4);
  });

  test('Pocket Change adds to the cash-out', () {
    final c = _container();
    final n = _cleared(c);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(jokers: [JokerRegistry.byId('joker_pocket_change').joker]),
    );
    n.collectCashOut();
    expect(c.read(runProvider).gold, 10 + 4 + 3 + 2 + 2);
  });

  test('cash out only works from blindCleared', () {
    final c = _container();
    c.read(runProvider.notifier).collectCashOut();
    expect(c.read(runProvider).status, RunStatus.playing);
  });

  test('buying a joker and a card spends gold and empties the slot', () {
    final c = _container();
    final n = _shop(c);
    final stock = c.read(runProvider).shop!.stock;
    final joker = stock.firstWhere((i) => i.isJoker);
    final card = stock.firstWhere((i) => !i.isJoker);
    n.buyItem(joker.id);
    n.buyItem(card.id);
    final s = c.read(runProvider);
    expect(s.gold, 30 - joker.price - card.price);
    expect(s.jokers.single.id, joker.id);
    expect(s.consumables, [card.id]);
    expect(s.shop!.stock.map((i) => i.id), isNot(contains(joker.id)));
  });

  test('cannot buy without money, with full slots, or outside the shop', () {
    final c = _container();
    final n = _shop(c, gold: 1);
    final stock = c.read(runProvider).shop!.stock;
    n.buyItem(stock.first.id);
    expect(c.read(runProvider).gold, 1);
    expect(c.read(runProvider).jokers, isEmpty);

    n.debugSet(
      c
          .read(runProvider)
          .copyWith(gold: 99, consumables: ['chisel_bonus', 'chisel_mult']),
    );
    n.buyItem(stock.firstWhere((i) => !i.isJoker).id);
    expect(c.read(runProvider).consumables.length, 2, reason: 'slots full');

    n.debugSet(c.read(runProvider).copyWith(status: RunStatus.playing));
    n.buyItem(stock.first.id);
    expect(c.read(runProvider).gold, 99, reason: 'not shopping');
  });

  test('5 joker limit', () {
    final c = _container();
    final n = _shop(c, gold: 99);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            jokers: [
              for (final d in JokerRegistry.all.skip(10).take(5)) d.joker,
            ],
          ),
    );
    final joker = c.read(runProvider).shop!.stock.firstWhere((i) => i.isJoker);
    n.buyItem(joker.id);
    expect(c.read(runProvider).jokers.length, 5);
    expect(c.read(runProvider).gold, 99);
  });

  test('reroll costs \$5 then \$6, replaces stock, needs money', () {
    final c = _container();
    final n = _shop(c);
    final before = c.read(runProvider).shop!.stock.map((i) => i.id).toList();
    n.rerollShop();
    expect(c.read(runProvider).gold, 25);
    n.rerollShop();
    expect(c.read(runProvider).gold, 19);
    expect(c.read(runProvider).shop!.rerolls, 2);
    expect(
      c.read(runProvider).shop!.stock.map((i) => i.id).toList(),
      isNot(before),
    );
    n.debugSet(c.read(runProvider).copyWith(gold: 4));
    n.rerollShop();
    expect(c.read(runProvider).gold, 4);
  });

  test('selling a joker pays half its price', () {
    final c = _container();
    final n = _shop(c);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(jokers: [JokerRegistry.byId('joker_gyroscope').joker]),
    );
    n.sellJoker(0);
    expect(c.read(runProvider).jokers, isEmpty);
    expect(c.read(runProvider).gold, 30 + 4);
  });

  test('item ids from the shop always resolve', () {
    for (var seed = 0; seed < 20; seed++) {
      final c = _container();
      _cleared(c).collectCashOut();
      for (final ShopItem i in c.read(runProvider).shop!.stock) {
        expect(i.isJoker ? JokerRegistry.maybeById(i.id) : i, isNotNull);
      }
    }
    expect(AnteScaling.baseTarget(1), 300);
  });
}
