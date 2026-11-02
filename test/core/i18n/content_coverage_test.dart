import 'package:blastro/core/i18n/app_strings.dart';
import 'package:blastro/core/i18n/str_keys_game.dart';
import 'package:blastro/core/i18n/supported_language.dart';
import 'package:blastro/core/roguelite/boss_blinds.dart';
import 'package:blastro/core/roguelite/consumables.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/starter_decks.dart';
import 'package:blastro/core/roguelite/vouchers.dart';
import 'package:blastro/core/scoring/clear_archetypes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every id the game can show, with its English text from the catalogs.
Map<String, (String, String)> _catalog() => {
  for (final j in JokerRegistry.all) j.id: (j.name, j.description),
  for (final c in ConsumableRegistry.all) c.id: (c.name, c.description),
  for (final v in VoucherRegistry.all) v.id: (v.name, v.description),
  for (final b in BossRegistry.all) b.id: (b.name, b.description),
  for (final d in StarterDecks.all) d.id: (d.name, d.description),
};

void main() {
  final catalog = _catalog();

  test('the catalog is the size we expect (25+20+4+10+5)', () {
    expect(catalog.length, 64);
  });

  for (final lang in Languages.all.where((l) => l.code != 'en')) {
    group('${lang.code} content', () {
      test('names and describes every joker, card, voucher, boss and deck', () {
        final missing = catalog.keys.where((id) => lang.content[id] == null);
        expect(missing, isEmpty);
      });

      test('has no ids the game does not know', () {
        final extra = lang.content.keys.where((id) => !catalog.containsKey(id));
        expect(extra, isEmpty);
      });

      test('no name or description is blank or left in English', () {
        for (final e in catalog.entries) {
          final t = lang.content[e.key]!;
          expect(t.name.trim(), isNotEmpty, reason: e.key);
          expect(t.description.trim(), isNotEmpty, reason: e.key);
          expect(t.description, isNot(e.value.$2), reason: '${e.key} copied');
        }
      });

      test('every joker has a card one-liner', () {
        for (final j in JokerRegistry.all) {
          expect(lang.content[j.id]!.short, isNotNull, reason: j.id);
          expect(lang.content[j.id]!.short!.trim(), isNotEmpty);
        }
      });

      test('keeps the numbers: each digit run in English survives', () {
        final digits = RegExp(r'\d+(\.\d+)?');
        for (final j in JokerRegistry.all) {
          final en = digits.allMatches(j.description).map((m) => m[0]!).toSet();
          final tr = digits
              .allMatches(lang.content[j.id]!.description)
              .map((m) => m[0]!)
              .toSet();
          expect(tr, en, reason: j.id);
        }
      });
    });
  }

  group('AppStrings lookups', () {
    final tr = AppStrings(Languages.turkish);
    final en = AppStrings(Languages.english);

    test('Turkish names for the sample cards from the brief', () {
      expect(tr.nameOf('joker_plain', 'Plain Joker'), 'Sade Joker');
      expect(tr.nameOf('boss_wall', 'The Wall'), 'Duvar');
      expect(tr.nameOf('chisel_glass', 'x'), 'Kalem: Cam');
    });

    test('English returns the catalog text, and unknown ids fall back', () {
      expect(en.nameOf('joker_plain', 'Plain Joker'), 'Plain Joker');
      expect(tr.nameOf('mystery', 'Mystery'), 'Mystery');
      expect(tr.descriptionOf('mystery', 'Does things'), 'Does things');
    });

    test('every clear type has a Turkish HUD name and plain name', () {
      for (final a in ClearArchetype.values) {
        expect(tr.archetype(a), isNot(en.archetype(a)), reason: a.name);
        expect(tr.archetypeName(a).trim(), isNotEmpty);
      }
      expect(tr.archetype(ClearArchetype.single), 'TEKLİ ÇİZGİ');
      expect(tr.archetype(ClearArchetype.crossClear), 'KESİŞEN ARTI!');
    });

    test('arguments are filled in', () {
      expect(tr.t(HudStr.calloutTrays, {'n': 8}), '+8 HAMLE!');
    });
  });
}
