import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/replay_totals.dart';

/// Blue Chips x Red Mult boxes, driven live by the score replay.
class HudScoreBoxes extends ConsumerWidget {
  const HudScoreBoxes({super.key});

  static String format(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(replayTotalsProvider);
    return Row(
      children: [
        Expanded(
          child: _box(format(totals.chips), 'CHIPS', const Color(0xFF1976D2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '×',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: _box(format(totals.mult), 'MULT', const Color(0xFFD32F2F)),
        ),
      ],
    );
  }

  Widget _box(String value, String label, Color color) => Container(
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.5)),
      ],
    ),
  );
}
