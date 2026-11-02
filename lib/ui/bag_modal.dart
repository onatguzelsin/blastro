import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/grid/grid_cell.dart';
import '../core/grid/grid_matrix.dart';
import '../core/polyomino/polyomino_catalog.dart';
import '../core/polyomino/polyomino_shape.dart';
import '../state/run_notifier.dart';
import 'consumable_row.dart';
import 'slide_up_sheet.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/supported_language.dart';
import '../core/i18n/str_keys_game.dart';
import '../state/locale_provider.dart';

/// Block Bag inspector: how many of each polyomino are still in the bag,
/// which board cells are enhanced, and the held cards.
class BagModal extends ConsumerWidget {
  const BagModal({super.key, required this.onClose});

  final VoidCallback onClose;

  /// Remaining count per catalog shape id (0 for shapes already drawn).
  /// [pool] is the deck's shapes (the whole catalog if omitted).
  static Map<String, int> countsById(
    List<Polyomino> remaining, [
    List<Polyomino>? pool,
  ]) {
    final counts = {for (final p in pool ?? PolyominoCatalog.all) p.id: 0};
    for (final p in remaining) {
      counts[p.id] = (counts[p.id] ?? 0) + 1;
    }
    return counts;
  }

  /// Human-readable tally of enhanced board cells, e.g. `Steel x2`.
  static List<String> enhancementSummary(
    GridMatrix grid, [
    AppStrings? strings,
  ]) {
    final s = strings ?? AppStrings(Languages.english);
    final tally = <String, int>{};
    for (var r = 0; r < GridMatrix.size; r++) {
      for (var c = 0; c < GridMatrix.size; c++) {
        final cell = grid.at(r, c);
        if (cell == null) continue;
        for (final name in [
          if (cell.enhancement != CellEnhancement.none)
            _enhancement(cell.enhancement, s),
          if (cell.edition != CellEdition.none) _edition(cell.edition, s),
          if (cell.seal != CellSeal.none)
            s.t(FlowStr.bagSeal, {'name': cell.seal.name}),
        ]) {
          tally[name] = (tally[name] ?? 0) + 1;
        }
      }
    }
    return [for (final e in tally.entries) '${e.key} x${e.value}'];
  }

  static String _enhancement(CellEnhancement e, AppStrings s) => switch (e) {
    CellEnhancement.bonus => s.t(FlowStr.enhBonus),
    CellEnhancement.mult => s.t(FlowStr.enhMult),
    CellEnhancement.glass => s.t(FlowStr.enhGlass),
    CellEnhancement.lucky => s.t(FlowStr.enhLucky),
    CellEnhancement.steel => s.t(FlowStr.enhSteel),
    CellEnhancement.none => '',
  };

  static String _edition(CellEdition e, AppStrings s) => switch (e) {
    CellEdition.foil => s.t(FlowStr.edFoil),
    CellEdition.holo => s.t(FlowStr.edHolo),
    CellEdition.polychrome => s.t(FlowStr.edPolychrome),
    CellEdition.none => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final t = strings.t;
    final s = ref.watch(runProvider);
    final remaining = ref.read(runProvider.notifier).bagRemaining;
    final deck = s.deck;
    final counts = countsById(remaining, deck.pool);
    final enhanced = enhancementSummary(s.grid, strings);
    return SlideUpSheet(
      title: t(FlowStr.bagTitle),
      trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(FlowStr.bagLeft, {
              'n': remaining.length,
              'total': deck.pool.length,
              'deck': strings.nameOf(deck.id, deck.name),
            }),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in deck.shapes)
                _PieceCount(piece: p, count: counts[p.id] ?? 0),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t(FlowStr.bagEnhanced),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            enhanced.isEmpty ? t(FlowStr.bagNone) : enhanced.join(' · '),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Text(
            t(FlowStr.bagCards),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const ConsumableRow(),
        ],
      ),
    );
  }
}

class _PieceCount extends StatelessWidget {
  const _PieceCount({required this.piece, required this.count});

  final Polyomino piece;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: count == 0 ? 0.35 : 1,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 28,
              child: CustomPaint(
                painter: _ThumbPainter(piece),
                size: const Size(40, 28),
              ),
            ),
            Text(
              'x$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.piece);

  final Polyomino piece;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = 5.5;
    final origin = Offset(
      (size.width - piece.width * cell) / 2,
      (size.height - piece.height * cell) / 2,
    );
    final paint = Paint()..color = const Color(0xFF5C8DFF);
    for (final o in piece.cells) {
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + o.col * cell,
          origin.dy + o.row * cell,
          cell - 1,
          cell - 1,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.piece != piece;
}
