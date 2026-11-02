import 'package:blastro/core/i18n/all_str_keys.dart';
import 'package:blastro/core/i18n/supported_language.dart';
import 'package:flutter_test/flutter_test.dart';

final _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _args(String s) => {
  for (final m in _placeholder.allMatches(s)) m.group(1)!,
};

void main() {
  for (final lang in Languages.all) {
    group('${lang.code} (${lang.nativeName}) UI strings', () {
      test('has every key, with zero missing', () {
        final missing = [
          for (final k in allStrKeys)
            if (!lang.ui.containsKey(k)) '${k.runtimeType}.${k.name}',
        ];
        expect(missing, isEmpty, reason: 'missing in ${lang.code}');
      });

      test('has no unknown extra keys', () {
        final known = allStrKeys.toSet();
        expect(lang.ui.keys.where((k) => !known.contains(k)), isEmpty);
      });

      test('no value is blank', () {
        final blank = [
          for (final e in lang.ui.entries)
            if (e.value.trim().isEmpty) e.key.name,
        ];
        expect(blank, isEmpty);
      });
    });
  }

  group('translations agree with English', () {
    final en = Languages.english;

    for (final lang in Languages.all.where((l) => l.code != 'en')) {
      test('${lang.code}: every {argument} matches English', () {
        final bad = [
          for (final k in allStrKeys)
            if (!_args(en.ui[k]!).containsAll(_args(lang.ui[k]!)) ||
                !_args(lang.ui[k]!).containsAll(_args(en.ui[k]!)))
              k.name,
        ];
        expect(bad, isEmpty);
      });

      test('${lang.code}: actually translated, not copied English', () {
        final same = [
          for (final k in allStrKeys)
            if (lang.ui[k] == en.ui[k]) k.name,
        ];
        // A few keys read the same in every language (numbers, "ANTE {n}").
        expect(same.length, lessThan(12), reason: same.join(', '));
      });
    }

    test('key names are unique across the enums', () {
      final names = allStrKeys.map((k) => '${k.runtimeType}.${k.name}');
      expect(names.toSet().length, allStrKeys.length);
    });
  });

  group('the registry', () {
    test('has English first (the fallback) and Turkish', () {
      expect(Languages.all.first.code, 'en');
      expect(Languages.all.map((l) => l.code), containsAll(['en', 'tr']));
    });

    test('codes and badges are unique and names are native', () {
      expect(
        Languages.all.map((l) => l.code).toSet().length,
        Languages.all.length,
      );
      expect(
        Languages.all.map((l) => l.badge).toSet().length,
        Languages.all.length,
      );
      expect(Languages.turkish.nativeName, 'Türkçe');
      expect(Languages.english.nativeName, 'English');
    });

    test('byCode falls back to English for unknown codes', () {
      expect(Languages.byCode('xx').code, 'en');
      expect(Languages.byCode(null).code, 'en');
      expect(Languages.byCode('tr').code, 'tr');
    });
  });
}
