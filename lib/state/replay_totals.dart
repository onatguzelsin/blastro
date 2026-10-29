import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live Chips x Mult shown in the HUD while a score replay plays.
class ReplayTotals {
  const ReplayTotals({this.chips = 0, this.mult = 0});

  final double chips;
  final double mult;
}

final replayTotalsProvider =
    NotifierProvider<ReplayTotalsNotifier, ReplayTotals>(
      ReplayTotalsNotifier.new,
    );

class ReplayTotalsNotifier extends Notifier<ReplayTotals> {
  @override
  ReplayTotals build() => const ReplayTotals();

  void set(double chips, double mult) =>
      state = ReplayTotals(chips: chips, mult: mult);
}
