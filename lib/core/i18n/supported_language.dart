import 'content_text.dart';
import 'str_key.dart';
import 'cards_strings_tr.dart';
import 'help_strings_en.dart';
import 'help_strings_tr.dart';
import 'ui_strings_en.dart';
import 'ui_strings_tr.dart';
import 'world_strings_tr.dart';

/// One language the app can show. To add a language (German, Spanish,
/// Japanese...): write its string maps, then add ONE entry to [Languages.all].
class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.nativeName,
    required this.badge,
    required this.ui,
    this.content = const {},
  });

  /// ISO 639-1 code, e.g. `en`. Also what is saved on disk.
  final String code;

  /// The language's own name, e.g. `Türkçe`.
  final String nativeName;

  /// A short flag-like badge for the picker.
  final String badge;

  /// Every [StrKey] translated.
  final Map<StrKey, String> ui;

  /// Names and descriptions of jokers, cards, vouchers, bosses and decks by
  /// id. Anything missing falls back to the English text in the catalogs.
  final Map<String, ContentText> content;
}

/// The registry of languages.
abstract final class Languages {
  static final SupportedLanguage english = SupportedLanguage(
    code: 'en',
    nativeName: 'English',
    badge: 'EN',
    ui: {...enUi, ...enHelp},
  );

  static final SupportedLanguage turkish = SupportedLanguage(
    code: 'tr',
    nativeName: 'Türkçe',
    badge: 'TR',
    ui: {...trUi, ...trHelp},
    content: {...trCards, ...trWorld},
  );

  /// The first entry is the fallback.
  static final List<SupportedLanguage> all = List.unmodifiable([
    english,
    turkish,
  ]);

  static SupportedLanguage byCode(String? code) =>
      all.firstWhere((l) => l.code == code, orElse: () => english);

  static bool supports(String? code) => all.any((l) => l.code == code);
}
