import 'supported_language.dart';

/// Which language to start in.
abstract final class AppLocale {
  /// The saved choice if it is still a supported language, else the device
  /// language if supported, else English.
  static SupportedLanguage resolve({String? saved, String? device}) {
    if (Languages.supports(saved)) return Languages.byCode(saved);
    if (Languages.supports(device)) return Languages.byCode(device);
    return Languages.english;
  }
}
