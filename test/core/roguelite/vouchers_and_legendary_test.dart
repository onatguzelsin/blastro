import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/blind_economy.dart';
import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/run_modifiers.dart';
import 'package:blastro/core/roguelite/shop_pricing.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:blastro/core/scoring/combo_window.dart';
import 'package:blastro/core/scoring/scoring_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

ScoreResult _score(GridMatrix g, List<String> ids) =>
    const ScoringPipeline().score(
      board: g,
      comboStreak: 0,
      jokers: [for (final id in ids) JokerRegistry.byId(id).joker],
    );

/// [lines] rows filled, plus a spare cell so it is never a Clean Sweep.
GridMatrix _rows(int lines) {
  final g = GridMatrix();
  for (var r = 0; r < lines; r++) {
    for (var c = 0; c < 8; c++) {
      g.setCell(r, c, GridCell.plain);
    }
  }
  return g..setCell(7, 7, GridCell.plain);
}

void main() {
  group('vouchers', () {
    test('what each one does', () {
      expect(VoucherRegistry.overstock.modifiers.shopJokerSlots, 1);
      expect(VoucherRegistry.clearanceSale.modifiers.priceDiscount, 0.25);
      expect(VoucherRegistry.seedMoney.modifiers.interestCap, 10);
      expect(VoucherRegistry.wasteful.modifiers.extraDiscards, 1);
    });

    test('lookup by id', () {
      expect(
        VoucherRegistry.byId('voucher_wasteful'),
        VoucherRegistry.wasteful,
      );
      expect(VoucherRegistry.maybeById('nope'), isNull);
      expect(() => VoucherRegistry.byId('nope'), throwsArgumentError);
    });

    test('modifiers combine: discounts add, caps take the max', () {
      final m = RunModifiers.combine([
        VoucherRegistry.clearanceSale.modifiers,
        const RunModifiers(priceDiscount: 0.1),
        VoucherRegistry.seedMoney.modifiers,
        VoucherRegistry.overstock.modifiers,
      ]);
      expect(m.priceDiscount, closeTo(0.35, 1e-9));
      expect(m.interestCap, 10);
      expect(m.shopJokerSlots, 1);
      expect(RunModifiers.none.interestCap, 5);
    });

    test('vouchers and jokers combine in one RunModifiers', () {
      final m = RunModifiers.fromRun(
        [JokerRegistry.byId('joker_discard_hoarder').joker],
        [VoucherRegistry.wasteful.modifiers],
      );
      expect(m.extraDiscards, 2);
    });

    test('Seed Money raises the interest cap at cash out', () {
      expect(
        BlindEconomy.breakdown(
          BlindType.small,
          gold: 100,
          traysRemaining: 1,
        ).interest,
        5,
      );
      expect(
        BlindEconomy.breakdown(
          BlindType.small,
          gold: 100,
          traysRemaining: 1,
          interestCap: 10,
        ).interest,
        10,
      );
      expect(
        BlindEconomy.breakdown(
          BlindType.small,
          gold: 30,
          traysRemaining: 1,
          interestCap: 10,
        ).interest,
        6,
      );
    });
  });

  group('Legendary jokers', () {
    test('three of them, all Legendary and \$22 or more', () {
      final ids = [
        'joker_singularity',
        'joker_phoenix_feather',
        'joker_grand_architect',
      ];
      for (final id in ids) {
        final d = JokerRegistry.byId(id);
        expect(d.rarity, JokerRarity.legendary, reason: id);
        expect(d.basePrice, greaterThanOrEqualTo(22));
      }
    });

    test('Singularity: x3 Mult', () {
      final base = _score(_rows(1), []);
      expect(
        _score(_rows(1), ['joker_singularity']).totalMult,
        base.totalMult * 3,
      );
    });

    test('Grand Architect: x1.5 per line, and they multiply', () {
      final one = _score(_rows(1), []).totalMult;
      expect(_score(_rows(1), ['joker_grand_architect']).totalMult, one * 1.5);
      final two = _score(_rows(2), []).totalMult;
      expect(
        _score(_rows(2), ['joker_grand_architect']).totalMult,
        closeTo(two * 2.25, 1e-9),
      );
      final three = _score(_rows(3), []).totalMult;
      expect(
        _score(_rows(3), ['joker_grand_architect']).totalMult,
        closeTo(three * 3.375, 1e-9),
      );
    });

    test('Phoenix Feather: the combo survives any number of non-clears', () {
      var w = const ComboWindow(streak: 6);
      final extra = JokerRegistry.byId('joker_phoenix_feather')
          .joker
          .modifiers
          .extraSetupMoves;
      for (var i = 0; i < 60; i++) {
        w = w.afterPlacement(cleared: false, extraSetupMoves: extra);
      }
      expect(w.streak, 6);
      // Without it the 3rd miss resets.
      var plain = const ComboWindow(streak: 6);
      for (var i = 0; i < 3; i++) {
        plain = plain.afterPlacement(cleared: false);
      }
      expect(plain.streak, 0);
    });

    test(
      'Violet Vessel marks the XMult legendaries but not Phoenix Feather',
      () {
        const b = BossRegistry.violetVessel;
        expect(
          b.debuffsJoker(JokerRegistry.byId('joker_singularity').joker),
          isTrue,
        );
        expect(
          b.debuffsJoker(JokerRegistry.byId('joker_grand_architect').joker),
          isTrue,
        );
        expect(
          b.debuffsJoker(JokerRegistry.byId('joker_phoenix_feather').joker),
          isFalse,
        );
      },
    );
  });

  group('economy sanity', () {
    test('a Rare joker at Ante 8 costs more than a whole Boss cash-out', () {
      final cashOut = BlindEconomy.breakdown(
        BlindType.boss,
        gold: 25,
        traysRemaining: 5,
      );
      final rare = ShopPricing.price(16, ante: 8);
      expect(rare, 33);
      expect(rare, greaterThan(cashOut.total));
    });
  });
}
