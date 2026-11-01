import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/scoring/score_preview.dart';

/// The live "if you drop it here" result shown in the HUD while a piece is
/// dragged over a clearing spot. Null when there is nothing to show.
final placementPreviewProvider =
    NotifierProvider<PlacementPreviewNotifier, PreviewSummary?>(
      PlacementPreviewNotifier.new,
    );

class PlacementPreviewNotifier extends Notifier<PreviewSummary?> {
  @override
  PreviewSummary? build() => null;

  /// Identical summaries are ignored, so hovering the same spot for many
  /// frames does not rebuild the HUD.
  void show(PreviewSummary? summary) {
    if (summary != state) state = summary;
  }

  void clear() => show(null);
}
