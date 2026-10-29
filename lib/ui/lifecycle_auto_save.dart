import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';

/// Saves the run whenever Android may kill the app: backgrounded
/// (`paused`), hidden, losing focus (`inactive`) or `detached`.
class LifecycleAutoSave extends ConsumerStatefulWidget {
  const LifecycleAutoSave({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LifecycleAutoSave> createState() => _LifecycleAutoSaveState();
}

class _LifecycleAutoSaveState extends ConsumerState<LifecycleAutoSave>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ref.read(runProvider.notifier).saveNow();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
