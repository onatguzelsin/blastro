import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';
import '../state/run_transitions.dart';
import 'hud_top_bar.dart';
import 'slide_up_sheet.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// Shown when a blind is defeated: base reward + unused trays + interest.
class CashOutSheet extends ConsumerWidget {
  const CashOutSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final s = ref.watch(runProvider);
    final b = RunTransitions.cashOut(s);
    return SlideUpSheet(
      title: t(FlowStr.cashTitle),
      child: Column(
        children: [
          Text(
            t(FlowStr.cashScore, {
              'blind': HudTopBar.blindName(s, strings),
              'score': s.score,
              'target': s.target,
            }),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          _line(t(FlowStr.cashReward), b.reward),
          _line(t(FlowStr.cashTrays), b.traysBonus),
          _line(t(FlowStr.cashInterest), b.interest),
          if (b.jokerBonus > 0) _line(t(FlowStr.cashJoker), b.jokerBonus),
          const Divider(height: 24),
          _line(t(FlowStr.cashTotal), b.total, bold: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(runProvider.notifier).collectCashOut(),
              child: Text(t(FlowStr.cashButton, {'n': b.total})),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 20 : 16,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      color: bold ? const Color(0xFFFFD54F) : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
          Text('+\$$amount', style: style),
        ],
      ),
    );
  }
}
