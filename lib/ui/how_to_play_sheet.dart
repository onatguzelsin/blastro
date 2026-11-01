import 'package:flutter/material.dart';

/// (title, body) pairs shown in the How to Play modal.
const List<(String, String)> howToPlaySections = [
  (
    'The goal',
    'Each Ante has three blinds: Small, Big and a Boss. Reach a blind\'s '
        'target score to beat it. Defeat the Ante 8 Boss to win, then keep '
        'going in Endless Mode up to Ante 39.',
  ),
  (
    'Placing pieces',
    'Drag a piece from the tray onto the 8x8 board. It is drawn above your '
        'finger so you can see it. Fill a whole row or column to clear it. '
        'Place all 3 pieces to get a new tray.',
  ),
  (
    'Scoring: Chips x Mult',
    '1. The clear type sets base Chips and Mult, plus your combo.\n'
        '2. Each cleared cell adds Chips (a cell where a row and column cross '
        'scores twice).\n'
        '3. Cells left on the board can score too (Steel x1.5).\n'
        '4. Jokers apply left to right, so their order matters.',
  ),
  (
    'Combo',
    'Every clearing move builds your combo and adds Mult. You can make 2 '
        'moves in a row without clearing; the 3rd one resets it.',
  ),
  (
    'Trays and discards',
    'Each blind gives you a limited number of trays. A Discard redraws the '
        'pieces you have not placed yet. When you beat a blind, any leftover '
        'pieces are thrown away and you get a fresh full tray. Your board '
        'stays as it is until a Boss is defeated.',
  ),
  (
    'Blinds, skipping and bosses',
    'Between blinds you choose what to play. Small and Big blinds can be '
        'skipped, but you give up their reward and the shop. The Boss cannot '
        'be skipped and has a debuff: its rule is shown on its card in advance, '
        'in a red banner during the round, and debuffed blocks and jokers get '
        'a red cross.',
  ),
  (
    'Shop',
    'After each blind you cash out and can buy up to 5 jokers and 2 cards, '
        'reroll the shop, or sell jokers. Interest pays \$1 per \$5 you hold.',
  ),
  (
    'Losing',
    'The run ends if you run out of trays below the target, or if no piece '
        'fits anywhere on the board and you have no discards left.',
  ),
];

/// Opens the How to Play modal.
Future<void> showHowToPlay(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => const HowToPlaySheet(),
);

class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF171B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'How to Play',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (title, body) in howToPlaySections) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
