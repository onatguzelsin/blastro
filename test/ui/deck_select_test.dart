import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/ui/deck_card.dart';
import 'package:blastro/ui/deck_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A host that opens the picker and records what it returned.
class _Host extends StatefulWidget {
  const _Host(this.onResult);

  final void Function(StarterDeck?) onResult;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final deck = await Navigator.of(context).push<StarterDeck>(
            MaterialPageRoute(builder: (_) => const DeckSelectScreen()),
          );
          widget.onResult(deck);
        },
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(WidgetTester t, void Function(StarterDeck?) onResult) async {
  await t.binding.setSurfaceSize(const Size(400, 860));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(ProviderScope(child: MaterialApp(home: _Host(onResult))));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

Future<void> _swipeNext(WidgetTester t) async {
  await t.fling(find.byType(PageView), const Offset(-320, 0), 1500);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('opens on the Standard Deck with its numbers', (t) async {
    await _open(t, (_) {});
    expect(find.text('CHOOSE YOUR DECK'), findsOneWidget);
    expect(find.text('Standard Deck'), findsOneWidget);
    expect(find.text('Standart Deste'), findsOneWidget);
    expect(find.textContaining('all 24 shapes'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('Start Run with This Deck'), findsOneWidget);
    expect(DeckCard.statsOf(StarterDecks.standard), [
      ('Trays', '5'),
      ('Discards', '3'),
      ('Colors', '4'),
      ('Pieces', '24'),
    ]);
  });

  testWidgets('swiping walks through all five decks in order', (t) async {
    await _open(t, (_) {});
    final expected = [
      ('Standard Deck', 'Standart Deste'),
      ('Monolith Cube Deck', 'Küp Envanteri'),
      ('Crimson Recycler Deck', 'Geri Dönüşüm Destesi'),
      ('Azure Architect Deck', 'Mimar Destesi'),
      ('Chromatic Flush Deck', 'İkili Renk Destesi'),
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(find.text(expected[i].$1), findsOneWidget, reason: 'page $i');
      expect(find.text(expected[i].$2), findsOneWidget);
      expect(find.text('${i + 1} / 5'), findsOneWidget);
      if (i < expected.length - 1) await _swipeNext(t);
    }
  });

  testWidgets('each deck shows its own rule and numbers', (t) async {
    await _open(t, (_) {});
    await _swipeNext(t);
    expect(find.textContaining('ONLY 2x2 and 3x3'), findsOneWidget);
    await _swipeNext(t);
    expect(find.textContaining('+1 discard every blind'), findsOneWidget);
    expect(DeckCard.statsOf(StarterDecks.crimsonRecycler)[1], (
      'Discards',
      '4',
    ));
    await _swipeNext(t);
    expect(find.textContaining('+1 tray every blind'), findsOneWidget);
    expect(DeckCard.statsOf(StarterDecks.azureArchitect)[0], ('Trays', '6'));
    await _swipeNext(t);
    expect(find.textContaining('only Red and Blue'), findsOneWidget);
    expect(DeckCard.statsOf(StarterDecks.chromaticFlush)[2], ('Colors', '2'));
  });

  testWidgets('the stat chips on screen match the deck', (t) async {
    await _open(t, (_) {});
    for (var i = 0; i < 3; i++) {
      await _swipeNext(t);
    }
    // Neighbouring pages are built too, so look inside the Azure card only.
    final card = find.ancestor(
      of: find.text('Azure Architect Deck'),
      matching: find.byType(DeckCard),
    );
    Finder inCard(String text) =>
        find.descendant(of: card, matching: find.text(text));
    expect(inCard('6'), findsOneWidget, reason: '6 trays');
    expect(inCard('3'), findsOneWidget, reason: '3 discards');
    expect(inCard('4'), findsOneWidget, reason: '4 colors');
    expect(inCard('24'), findsOneWidget, reason: '24 pieces');
    expect(inCard('Trays'), findsOneWidget);
  });

  testWidgets('tapping a page dot jumps to that deck', (t) async {
    await _open(t, (_) {});
    await t.tap(find.byKey(const ValueKey('deck_dot_3')));
    await t.pumpAndSettle();
    expect(find.text('Azure Architect Deck'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
  });

  testWidgets('Start Run returns the deck you are looking at', (t) async {
    StarterDeck? picked;
    await _open(t, (d) => picked = d);
    await t.tap(find.text('Start Run with This Deck'));
    await t.pumpAndSettle();
    expect(picked, StarterDecks.standard);
  });

  testWidgets('after swiping, Start returns THAT deck', (t) async {
    final results = <String?>[];
    await _open(t, (d) => results.add(d?.id));
    await _swipeNext(t);
    await _swipeNext(t);
    await t.tap(find.text('Start Run with This Deck'));
    await t.pumpAndSettle();
    expect(results, ['deck_crimson_recycler']);
  });

  testWidgets('every deck can be chosen', (t) async {
    for (var i = 0; i < StarterDecks.all.length; i++) {
      StarterDeck? picked;
      await _open(t, (d) => picked = d);
      await t.tap(find.byKey(ValueKey('deck_dot_$i')));
      await t.pumpAndSettle();
      await t.tap(find.text('Start Run with This Deck'));
      await t.pumpAndSettle();
      expect(picked, StarterDecks.all[i]);
    }
  });

  testWidgets('Back returns nothing', (t) async {
    final results = <StarterDeck?>[];
    await _open(t, results.add);
    await t.tap(find.text('Back'));
    await t.pumpAndSettle();
    expect(results, [null]);
  });
}
