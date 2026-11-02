import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../core/i18n/supported_language.dart';
import 'run_state.dart';

/// Short description of a saved run for the Continue button, in the
/// language of [strings] (English if omitted).
class RunSummary {
  RunSummary(this.state, [AppStrings? strings])
    : strings = strings ?? AppStrings(Languages.english);

  final RunState state;
  final AppStrings strings;

  /// The starter deck's name, e.g. `Monolith Cube Deck`.
  String get deckName => strings.nameOf(state.deck.id, state.deck.name);

  String get headline {
    final s = state;
    if (s.mode.isQuickPlay) return strings.t(HudStr.summaryQuick);
    return strings.t(HudStr.summaryAnteBlind, {
      'n': s.ante,
      'blind': strings.blind(s.blind),
      'mode': s.endless ? strings.t(HudStr.summaryEndless) : '',
    });
  }

  String get detail {
    final s = state;
    if (s.mode.isQuickPlay) {
      return strings.t(HudStr.summaryQuickDetail, {
        'score': s.score,
        'trays': s.traysRemaining,
        'combo': s.combo.streak,
      });
    }
    final where = switch (s.status) {
      RunStatus.playing => strings.t(HudStr.summaryScore, {
        'score': s.score,
        'target': s.target,
      }),
      RunStatus.blindSelect => strings.t(HudStr.summaryChoosing),
      RunStatus.blindCleared => strings.t(HudStr.summaryCleared),
      RunStatus.shopping => strings.t(HudStr.summaryShop),
      RunStatus.victory => strings.t(HudStr.summaryVictory),
      RunStatus.lost => strings.t(HudStr.summaryOver),
    };
    return '$where · \$${s.gold}';
  }
}
