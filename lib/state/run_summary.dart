import 'run_state.dart';

/// Short description of a saved run for the Continue button.
class RunSummary {
  const RunSummary(this.state);

  final RunState state;

  String get headline {
    final s = state;
    final mode = s.endless ? ' · Endless' : '';
    return 'Ante ${s.ante} · ${s.blind.displayName}$mode';
  }

  String get detail {
    final s = state;
    final where = switch (s.status) {
      RunStatus.playing => 'Score ${s.score} / ${s.target}',
      RunStatus.blindSelect => 'Choosing a blind',
      RunStatus.blindCleared => 'Blind defeated',
      RunStatus.shopping => 'In the shop',
      RunStatus.victory => 'Victory!',
      RunStatus.lost => 'Run over',
    };
    return '$where · \$${s.gold}';
  }
}
