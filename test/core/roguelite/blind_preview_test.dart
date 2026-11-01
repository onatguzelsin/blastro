import 'package:blastro/core/roguelite/ante_scaling.dart';
import 'package:blastro/core/roguelite/blind_preview.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:flutter_test/flutter_test.dart';

List<BlindPreview> _cards(
  BlindType current, {
  int ante = 1,
  int seed = 1,
  Set<BlindType> skipped = const {},
}) => BlindPreviews.forAnte(
  ante: ante,
  seed: seed,
  current: current,
  skipped: skipped,
);

List<BlindCardStatus> _statuses(List<BlindPreview> c) =>
    c.map((p) => p.status).toList();

int _seedForBoss(BossBlind boss, int ante) => List.generate(
  3000,
  (i) => i,
).firstWhere((s) => BossRegistry.pick(ante, s) == boss);

void main() {
  test('three cards in order: Small, Big, Boss', () {
    expect(_cards(BlindType.small).map((c) => c.blind), BlindType.values);
  });

  test('statuses: current is playable, earlier done, later locked', () {
    expect(_statuses(_cards(BlindType.small)), [
      BlindCardStatus.current,
      BlindCardStatus.locked,
      BlindCardStatus.locked,
    ]);
    expect(_statuses(_cards(BlindType.big)), [
      BlindCardStatus.completed,
      BlindCardStatus.current,
      BlindCardStatus.locked,
    ]);
    expect(_statuses(_cards(BlindType.boss)), [
      BlindCardStatus.completed,
      BlindCardStatus.completed,
      BlindCardStatus.current,
    ]);
  });

  test('a skipped blind is shown as skipped, not completed', () {
    final c = _cards(BlindType.boss, skipped: {BlindType.small});
    expect(_statuses(c), [
      BlindCardStatus.skipped,
      BlindCardStatus.completed,
      BlindCardStatus.current,
    ]);
  });

  test('targets: 1x / 1.5x / 2x of the ante base', () {
    expect(_cards(BlindType.small).map((c) => c.target), [300, 450, 600]);
  });

  test('rewards: \$4 / \$6 / \$8', () {
    expect(_cards(BlindType.small).map((c) => c.reward), [4, 6, 8]);
  });

  test(
    'only the Boss card carries a boss, and it is the one the run faces',
    () {
      final c = _cards(BlindType.small, ante: 3, seed: 42);
      expect(c[0].boss, isNull);
      expect(c[1].boss, isNull);
      expect(c[2].boss, BossRegistry.pick(3, 42));
    },
  );

  test('The Wall card shows its real 4x target', () {
    final seed = _seedForBoss(BossRegistry.wall, 1);
    expect(_cards(BlindType.small, seed: seed)[2].target, 1200);
  });

  test('Ante 8 Boss card is Violet Vessel at 100,000', () {
    final boss = _cards(BlindType.small, ante: 8)[2];
    expect(boss.boss, BossRegistry.violetVessel);
    expect(boss.target, 100000);
  });

  test('only a current Small or Big blind can be skipped', () {
    final small = _cards(BlindType.small);
    expect(small.map((c) => c.canSkip), [true, false, false]);
    final big = _cards(BlindType.big);
    expect(big.map((c) => c.canSkip), [false, true, false]);
    final boss = _cards(BlindType.boss);
    expect(boss.map((c) => c.canSkip), [false, false, false]);
  });

  test('preview is stable for a given ante and seed', () {
    expect(
      _cards(BlindType.small, seed: 9)[2].boss,
      _cards(BlindType.big, seed: 9)[2].boss,
    );
  });
}
