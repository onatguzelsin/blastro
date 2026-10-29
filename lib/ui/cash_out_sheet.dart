import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';
import '../state/run_transitions.dart';
import 'hud_top_bar.dart';
import 'slide_up_sheet.dart';

/// Shown when a blind is defeated: base reward + unused trays + interest.
class CashOutSheet extends ConsumerWidget {
  const CashOutSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    final b = RunTransitions.cashOut(s);
    return SlideUpSheet(
      title: 'Blind Defeated!',
      child: Column(
        children: [
          Text(
            '${HudTopBar.blindName(s)} · Score ${s.score} / ${s.target}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          _line('Blind reward', b.reward),
          _line('Unused trays', b.traysBonus),
          _line('Interest (\$1 per \$5)', b.interest),
          if (b.jokerBonus > 0) _line('Joker bonus', b.jokerBonus),
          const Divider(height: 24),
          _line('Total', b.total, bold: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(runProvider.notifier).collectCashOut(),
              child: Text('Cash Out  \$${b.total}'),
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
