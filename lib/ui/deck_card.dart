import 'package:flutter/material.dart';

import '../core/roguelite/starter_decks.dart';
import 'deck_emblem.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';
import '../core/i18n/supported_language.dart';

/// One starter deck's page: emblem, names, its rule and its numbers.
class DeckCard extends ConsumerWidget {
  const DeckCard({super.key, required this.deck});

  final StarterDeck deck;

  /// The four stat chips: label and value.
  static List<(String, String)> statsOf(
    StarterDeck deck, [
    AppStrings? strings,
  ]) {
    final s = strings ?? AppStrings(Languages.english);
    return [
      (s.t(MenuStr.deckTrays), '${deck.traysPerBlind}'),
      (s.t(MenuStr.deckDiscards), '${deck.discardsPerBlind}'),
      (s.t(MenuStr.deckColors), '${deck.colors.length}'),
      (s.t(MenuStr.deckPieces), '${deck.pool.length}'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final accent = accentOf(deck);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.12),
          const Color(0xFF14171F),
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent, width: 2.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 18),
        ],
      ),
      // Centered, so the card does not look empty below the stats; still
      // scrolls on a short screen.
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: DeckEmblem(deckId: deck.id, size: 104),
              ),
              const SizedBox(height: 18),
              Text(
                strings.nameOf(deck.id, deck.name),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.code == 'en' ? deck.nameTr : deck.name,
                style: TextStyle(
                  fontSize: 14,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.descriptionOf(deck.id, deck.description),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, value) in statsOf(deck, strings))
                    _chip(label, value, accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    ),
  );
}
