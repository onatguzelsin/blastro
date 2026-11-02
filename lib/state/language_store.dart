import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language the player picked. Null until they pick one, so a
/// fresh install follows the device language.
class LanguageStore {
  const LanguageStore(this._prefs);

  static const String key = 'blastro_language';

  final SharedPreferences _prefs;

  String? load() => _prefs.getString(key);

  Future<void> save(String code) => _prefs.setString(key, code);
}
