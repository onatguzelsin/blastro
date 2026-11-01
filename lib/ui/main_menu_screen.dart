import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/run_notifier.dart';
import '../state/run_persistence.dart';
import '../state/run_state_codec.dart';
import '../state/run_summary.dart';
import 'game_screen.dart';
import 'how_to_play_sheet.dart';

/// First screen: New Run, Continue Run (only with an active auto-save), and
/// the rules.
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  SavedRun? _saved;

  @override
  void initState() {
    super.initState();
    _saved = ref.read(runPersistenceProvider)?.load();
  }

  Future<void> _openGame() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    // Coming back: the run was auto-saved, so re-read it for Continue.
    if (mounted) {
      setState(() => _saved = ref.read(runPersistenceProvider)?.load());
    }
  }

  Future<void> _newRun() async {
    if (_saved != null && !await _confirmAbandon()) return;
    ref.read(runProvider.notifier).startRun();
    await _openGame();
  }

  Future<bool> _confirmAbandon() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new run?'),
        content: const Text('Your run in progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New Run'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _LogoMark(),
              const SizedBox(height: 18),
              const Text(
                'BLASTRO',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Block puzzle meets roguelite',
                style: TextStyle(color: Colors.white54),
              ),
              const Spacer(flex: 2),
              _MenuButton(
                label: 'Continue Run',
                subtitle: saved == null
                    ? 'No run in progress'
                    : '${RunSummary(saved.state).headline}\n'
                          '${RunSummary(saved.state).detail}',
                onPressed: saved == null ? null : _openGame,
                primary: true,
              ),
              const SizedBox(height: 12),
              _MenuButton(label: 'New Run', onPressed: _newRun),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'How to Play',
                onPressed: () => showHowToPlay(context),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.primary = false,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
      ],
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(58)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// The launcher-icon block mark, drawn with plain containers.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  static const _pattern = [
    [0xFF5C8DFF, 0xFF5C8DFF, 0xFF5C8DFF],
    [0xFFEF5350, null, 0xFFFFD54F],
    [0xFFEF5350, 0xFFEF5350, 0xFFFFD54F],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _pattern)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in row)
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c == null ? null : Color(c),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
