import '../roguelite/ante_scaling.dart';
import '../scoring/clear_archetypes.dart';
import 'content_text.dart';
import 'str_key.dart';
import 'str_keys_game.dart';
import 'supported_language.dart';

/// Looks up every piece of player-facing text for one language.
///
/// `s.t(MenuStr.newRun)` for UI text, `s.t(HudStr.calloutTrays, {'n': 8})` for
/// text with arguments, and `s.contentFor(id)` for jokers, cards, vouchers,
/// bosses and decks. A missing entry falls back to English instead of
/// crashing; tests make sure none is missing.
class AppStrings {
  const AppStrings(this.language);

  final SupportedLanguage language;

  String get code => language.code;

  /// The text for [key], with each `{name}` replaced from [args].
  String t(StrKey key, [Map<String, Object> args = const {}]) {
    var text = language.ui[key] ?? Languages.english.ui[key] ?? key.name;
    args.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
    return text;
  }

  /// The translation of catalog item [id], or null for the English original.
  ContentText? contentFor(String id) => language.content[id];

  /// Localized name of catalog item [id], else [english].
  String nameOf(String id, String english) => contentFor(id)?.name ?? english;

  /// Localized description of catalog item [id], else [english].
  String descriptionOf(String id, String english) =>
      contentFor(id)?.description ?? english;

  /// A joker's card one-liner, else [english].
  String shortOf(String id, String english) => contentFor(id)?.short ?? english;

  String archetype(ClearArchetype a) => t(switch (a) {
    ClearArchetype.single => HudStr.archSingle,
    ClearArchetype.parallelDouble => HudStr.archParallelDouble,
    ClearArchetype.crossClear => HudStr.archCrossClear,
    ClearArchetype.triple => HudStr.archTriple,
    ClearArchetype.doubleCross => HudStr.archDoubleCross,
    ClearArchetype.quad => HudStr.archQuad,
    ClearArchetype.zone3x3 => HudStr.archZone3x3,
    ClearArchetype.penta => HudStr.archPenta,
    ClearArchetype.hexa => HudStr.archHexa,
    ClearArchetype.cleanSweep => HudStr.archCleanSweep,
  });

  /// The plain clear-type name, e.g. `Parallel Double` (no `!`).
  String archetypeName(ClearArchetype a) => t(switch (a) {
    ClearArchetype.single => HudStr.nameSingle,
    ClearArchetype.parallelDouble => HudStr.nameParallelDouble,
    ClearArchetype.crossClear => HudStr.nameCrossClear,
    ClearArchetype.triple => HudStr.nameTriple,
    ClearArchetype.doubleCross => HudStr.nameDoubleCross,
    ClearArchetype.quad => HudStr.nameQuad,
    ClearArchetype.zone3x3 => HudStr.nameZone3x3,
    ClearArchetype.penta => HudStr.namePenta,
    ClearArchetype.hexa => HudStr.nameHexa,
    ClearArchetype.cleanSweep => HudStr.nameCleanSweep,
  });

  String blind(BlindType b) => t(switch (b) {
    BlindType.small => HudStr.blindSmall,
    BlindType.big => HudStr.blindBig,
    BlindType.boss => HudStr.blindBoss,
  });
}
