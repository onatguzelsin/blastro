import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnteScaling', () {
    test('Ante 1 = 300, Ante 8 = 50,000', () {
      expect(AnteScaling.baseTarget(1), 300);
      expect(AnteScaling.baseTarget(8), 50000);
    });

    test('blind multipliers 1x / 1.5x / 2x', () {
      expect(AnteScaling.blindTarget(1, BlindType.small), 300);
      expect(AnteScaling.blindTarget(1, BlindType.big), 450);
      expect(AnteScaling.blindTarget(1, BlindType.boss), 600);
    });

    test('Ante 8 Boss is the 100,000 Finisher', () {
      expect(AnteScaling.blindTarget(8, BlindType.boss), 100000);
      expect(AnteScaling.isFinisher(8, BlindType.boss), isTrue);
      expect(AnteScaling.isFinisher(8, BlindType.big), isFalse);
      expect(AnteScaling.isFinisher(7, BlindType.boss), isFalse);
    });

    test('targets strictly increase through Endless Ante 39', () {
      for (var a = 2; a <= AnteScaling.lastEndlessAnte; a++) {
        expect(
          AnteScaling.baseTarget(a),
          greaterThan(AnteScaling.baseTarget(a - 1)),
          reason: 'ante $a',
        );
      }
      expect(AnteScaling.isEndless(9), isTrue);
      expect(AnteScaling.isEndless(8), isFalse);
    });

    test('out-of-range antes throw', () {
      expect(() => AnteScaling.baseTarget(0), throwsRangeError);
      expect(() => AnteScaling.baseTarget(40), throwsRangeError);
    });
  });

  group('BlindEconomy', () {
    test('rewards scale with the blind', () {
      expect(BlindEconomy.reward(BlindType.small), 4);
      expect(BlindEconomy.reward(BlindType.big), 6);
      expect(BlindEconomy.reward(BlindType.boss), 8);
    });

    test('interest: \$1 per \$5, capped at \$5', () {
      expect(BlindEconomy.interest(0), 0);
      expect(BlindEconomy.interest(4), 0);
      expect(BlindEconomy.interest(5), 1);
      expect(BlindEconomy.interest(14), 2);
      expect(BlindEconomy.interest(25), 5);
      expect(BlindEconomy.interest(500), 5);
    });

    test('payout combines reward, interest and bonus', () {
      expect(
        BlindEconomy.payout(BlindType.boss, gold: 20, bonus: 2),
        8 + 4 + 2,
      );
    });
  });
}
