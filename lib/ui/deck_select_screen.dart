import 'package:flutter/material.dart';

import '../core/roguelite/starter_decks.dart';
import 'deck_card.dart';
import 'deck_emblem.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';

/// Pick the starter deck for a new run: swipe through the decks and tap
/// "Start Run with This Deck". Pops with the chosen [StarterDeck] (or null if
/// the player goes back).
class DeckSelectScreen extends ConsumerStatefulWidget {
  const DeckSelectScreen({super.key});

  @override
  ConsumerState<DeckSelectScreen> createState() => _DeckSelectScreenState();
}

class _DeckSelectScreenState extends ConsumerState<DeckSelectScreen> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  List<StarterDeck> get _decks => StarterDecks.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider).t;
    final deck = _decks[_page];
    final accent = accentOf(deck);
    return Scaffold(
      backgroundColor: const Color(0xFF0F1220),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(t(MenuStr.back)),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1} / ${_decks.length}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              t(MenuStr.deckChoose),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t(MenuStr.deckSwipe),
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _decks.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => DeckCard(deck: _decks[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _decks.length; i++)
                  GestureDetector(
                    key: ValueKey('deck_dot_$i'),
                    onTap: () => _goTo(i),
                    child: Container(
                      width: i == _page ? 22 : 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: i == _page ? accent : Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(deck),
                  child: Text(
                    t(MenuStr.deckStart),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
