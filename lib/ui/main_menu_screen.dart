import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_menu.dart';
import '../core/roguelite/run_mode.dart';
import '../core/roguelite/starter_decks.dart';
import '../state/locale_provider.dart';
import '../state/quick_play_records.dart';
import '../state/run_notifier.dart';
import '../state/run_persistence.dart';
import '../state/run_state_codec.dart';
import '../state/run_summary.dart';
import 'deck_select_screen.dart';
import 'game_screen.dart';
import 'how_to_play_sheet.dart';
import 'language_button.dart';
import 'logo_mark.dart';
import 'menu_button.dart';
import 'quick_play_button.dart';

/// First screen: New Run, Continue Run (only with an active auto-save), and
/// the rules.
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  /// The normal run's save slot, and the Quick Play run's. They are separate
  /// files: Quick Play never reads, overwrites or deletes the normal run.
  SavedRun? _saved;
  SavedRun? _quickSaved;

  @override
  void initState() {
    super.initState();
    _readSaves();
  }

  void _readSaves() {
    final store = ref.read(runPersistenceProvider);
    _saved = store?.load();
    _quickSaved = store?.load(RunMode.quickPlay);
  }

  Future<void> _openGame() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    // Coming back: everything was auto-saved, so re-read both slots.
    if (mounted) setState(_readSaves);
  }

  /// Quick Play: straight onto the board. Resumes your saved Quick Play run
  /// if there is one, else starts a new one. Your normal run is untouched.
  Future<void> _playQuick() async {
    final notifier = ref.read(runProvider.notifier);
    final saved = _quickSaved;
    saved == null ? notifier.startQuickPlay() : notifier.resumeRun(saved);
    await _openGame();
  }

  Future<void> _restartQuick() async {
    final t = ref.read(stringsProvider).t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(MenuStr.restartQuickTitle)),
        content: Text(t(MenuStr.restartQuickBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t(MenuStr.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t(MenuStr.restart)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(runProvider.notifier).startQuickPlay();
    await _openGame();
  }

  Future<void> _continue() async {
    ref.read(runProvider.notifier).resumeRun(_saved!);
    await _openGame();
  }

  Future<void> _newRun() async {
    if (_saved != null && !await _confirmAbandon()) return;
    if (!mounted) return;
    // New Run opens the deck picker first; Back from it cancels.
    final deck = await Navigator.of(context).push<StarterDeck>(
      MaterialPageRoute(builder: (_) => const DeckSelectScreen()),
    );
    if (deck == null || !mounted) return;
    ref.read(runProvider.notifier).startRun(null, deck);
    await _openGame();
  }

  Future<bool> _confirmAbandon() async {
    final t = ref.read(stringsProvider).t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(MenuStr.newRunTitle)),
        content: Text(t(MenuStr.newRunBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t(MenuStr.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t(MenuStr.newRun)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final saved = _saved;
    final quick = _quickSaved;
    final summary = saved == null ? null : RunSummary(saved.state, strings);
    return Scaffold(
      backgroundColor: const Color(0xFF0F1220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoMark(),
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
              Text(
                t(MenuStr.tagline),
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(flex: 2),
              QuickPlayButton(
                onPressed: _playQuick,
                best: ref.watch(quickPlayBestProvider),
                subtitle: quick == null
                    ? t(MenuStr.quickPlayInstant)
                    : t(MenuStr.quickPlayResume, {
                        'score': quick.state.score,
                        'trays': quick.state.traysRemaining,
                      }),
              ),
              if (quick != null)
                TextButton(
                  onPressed: _restartQuick,
                  child: Text(t(MenuStr.restartQuick)),
                ),
              const SizedBox(height: 12),
              MenuButton(
                label: t(MenuStr.continueRun),
                subtitle: summary == null
                    ? t(MenuStr.noRun)
                    : '${summary.headline}\n${summary.detail}\n'
                          '${summary.deckName}',
                onPressed: saved == null ? null : _continue,
                primary: true,
              ),
              const SizedBox(height: 12),
              MenuButton(label: t(MenuStr.newRun), onPressed: _newRun),
              const SizedBox(height: 12),
              MenuButton(
                label: t(MenuStr.howToPlay),
                onPressed: () => showHowToPlay(context),
              ),
              const SizedBox(height: 12),
              const LanguageButton(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
