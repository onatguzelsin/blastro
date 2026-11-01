import 'ante_scaling.dart';
import 'blind_economy.dart';
import 'boss_blinds.dart';

enum BlindCardStatus { completed, skipped, current, locked }

/// One card of the Blind Select screen.
class BlindPreview {
  const BlindPreview({
    required this.blind,
    required this.status,
    required this.target,
    required this.reward,
    this.boss,
  });

  final BlindType blind;
  final BlindCardStatus status;

  /// Score needed (the Boss card already includes the boss's multiplier).
  final int target;

  /// Base cash reward, before interest and unused-tray bonuses.
  final int reward;

  /// The Boss's rule, so the player can prepare during Small/Big.
  final BossBlind? boss;

  /// Only Small and Big can be skipped, and only while it is their turn.
  bool get canSkip =>
      status == BlindCardStatus.current && blind != BlindType.boss;
}

abstract final class BlindPreviews {
  static const List<BlindType> order = [
    BlindType.small,
    BlindType.big,
    BlindType.boss,
  ];

  /// The three blinds of [ante] with their status relative to [current].
  /// The Boss is the same one the run will face (`BossRegistry.pick`).
  static List<BlindPreview> forAnte({
    required int ante,
    required int seed,
    required BlindType current,
    Set<BlindType> skipped = const {},
  }) {
    final boss = BossRegistry.pick(ante, seed);
    return [
      for (final blind in order)
        BlindPreview(
          blind: blind,
          status: _status(blind, current, skipped),
          target: AnteScaling.targetFor(
            ante,
            blind,
            bossMultiplier: boss.targetMultiplier,
          ),
          reward: BlindEconomy.reward(blind),
          boss: blind == BlindType.boss ? boss : null,
        ),
    ];
  }

  static BlindCardStatus _status(
    BlindType blind,
    BlindType current,
    Set<BlindType> skipped,
  ) {
    if (blind == current) return BlindCardStatus.current;
    if (order.indexOf(blind) > order.indexOf(current)) {
      return BlindCardStatus.locked;
    }
    return skipped.contains(blind)
        ? BlindCardStatus.skipped
        : BlindCardStatus.completed;
  }
}
