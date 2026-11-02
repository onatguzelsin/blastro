import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_locale.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/supported_language.dart';
import 'language_store.dart';

/// Overridden in `main()`; null disables saving (tests).
final languageStoreProvider = Provider<LanguageStore?>((ref) => null);

/// The device's language code (`tr`, `en`...). Overridable in tests.
final deviceLanguageProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);

/// The active language. Picking one rebuilds every screen at once and saves
/// the choice; until then it follows the device language.
final languageProvider = NotifierProvider<LanguageNotifier, SupportedLanguage>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<SupportedLanguage> {
  @override
  SupportedLanguage build() => AppLocale.resolve(
    saved: ref.read(languageStoreProvider)?.load(),
    device: ref.read(deviceLanguageProvider),
  );

  void select(SupportedLanguage language) {
    state = language;
    ref.read(languageStoreProvider)?.save(language.code);
  }
}

/// What widgets watch: `ref.watch(stringsProvider).t(MenuStr.newRun)`.
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings(ref.watch(languageProvider)),
);
