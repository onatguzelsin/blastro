import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// Shown when a lose condition ends the run.
class RunOverOverlay extends ConsumerWidget {
  const RunOverOverlay({super.key, required this.onNewRun});

  final VoidCallback onNewRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(runProvider);
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(FlowStr.overTitle),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              t(FlowStr.overLine, {
                'ante': s.ante,
                'score': s.score,
                'target': s.target,
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onNewRun, child: Text(t(FlowStr.overNew))),
          ],
        ),
      ),
    );
  }
}
