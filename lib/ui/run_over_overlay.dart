import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';

/// Shown when a lose condition ends the run.
class RunOverOverlay extends ConsumerWidget {
  const RunOverOverlay({super.key, required this.onNewRun});

  final VoidCallback onNewRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runProvider);
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RUN OVER',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Ante ${s.ante} · Score ${s.score} / ${s.target}'),
            const SizedBox(height: 20),
            FilledButton(onPressed: onNewRun, child: const Text('New Run')),
          ],
        ),
      ),
    );
  }
}
