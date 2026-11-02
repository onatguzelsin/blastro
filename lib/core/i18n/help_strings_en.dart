import 'str_key.dart';
import 'str_keys_help.dart';

/// English: How to Play.
final Map<StrKey, String> enHelp = {
  HelpStr.title: 'How to Play',
  HelpStr.goalHead: 'The goal',
  HelpStr.goalBody:
      "Each Ante has three blinds: Small, Big and a Boss. Reach a blind's "
      'target score to beat it. Defeat the Ante 8 Boss to win, then keep '
      'going in Endless Mode up to Ante 39.',
  HelpStr.placingHead: 'Placing pieces',
  HelpStr.placingBody:
      'Drag a piece from the tray onto the 8x8 board. It is drawn above your '
      'finger so you can see it. Fill a whole row or column to clear it. '
      'Place all 3 pieces to get a new tray.',
  HelpStr.scoringHead: 'Scoring: Chips x Mult',
  HelpStr.scoringBody:
      '1. The clear type sets base Chips and Mult, plus your combo.\n'
      '2. Each cleared cell adds Chips (a cell where a row and column cross '
      'scores twice).\n'
      '3. Cells left on the board can score too (Steel x1.5).\n'
      '4. Jokers apply left to right, so their order matters.',
  HelpStr.comboHead: 'Combo',
  HelpStr.comboBody:
      'Every clearing move builds your combo and adds Mult. You can make 2 '
      'moves in a row without clearing; the 3rd one resets it.',
  HelpStr.traysHead: 'Trays and discards',
  HelpStr.traysBody:
      'Each blind gives you a limited number of trays. A Discard redraws the '
      'pieces you have not placed yet. When you beat a blind, any leftover '
      'pieces are thrown away and you get a fresh full tray. Your board '
      'stays as it is until a Boss is defeated.',
  HelpStr.blindsHead: 'Blinds, skipping and bosses',
  HelpStr.blindsBody:
      'Between blinds you choose what to play. Small and Big blinds can be '
      'skipped, but you give up their reward and the shop. The Boss cannot '
      'be skipped and has a debuff: its rule is shown on its card in advance, '
      'in a red banner during the round, and debuffed blocks and jokers get '
      'a red cross.',
  HelpStr.shopHead: 'Shop',
  HelpStr.shopBody:
      'After each blind you cash out and can buy up to 5 jokers and 2 cards, '
      'reroll the shop, or sell jokers. Interest pays \$1 per \$5 you hold.',
  HelpStr.losingHead: 'Losing',
  HelpStr.losingBody:
      'The run ends if you run out of trays below the target, or if no piece '
      'fits anywhere on the board and you have no discards left.',
};
