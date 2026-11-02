import 'package:blastro/core/i18n/supported_language.dart';
import 'package:blastro/state/language_store.dart';
import 'package:blastro/state/locale_provider.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/ui/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> _menu(
  WidgetTester t, {
  String device = 'en',
  String? saved,
}) async {
  SharedPreferences.setMockInitialValues({LanguageStore.key: ?saved});
  final prefs = await SharedPreferences.getInstance();
  await t.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer(
    overrides: [
      languageStoreProvider.overrideWithValue(LanguageStore(prefs)),
      deviceLanguageProvider.overrideWithValue(device),
    ],
  );
  addTearDown(c.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: MainMenuScreen()),
    ),
  );
  await t.pump();
  return (c, prefs);
}

Future<void> _openPicker(WidgetTester t) async {
  await t.tap(
    find.text('Language / Dil').evaluate().isNotEmpty
        ? find.text('Language / Dil')
        : find.text('Dil / Language'),
  );
  await t.pumpAndSettle();
}

void main() {
  group('the Language button on the Main Menu', () {
    testWidgets('says "Language / Dil" and shows the active language', (
      t,
    ) async {
      await _menu(t);
      expect(find.text('Language / Dil'), findsOneWidget);
      expect(find.text('EN · English'), findsOneWidget);
    });

    testWidgets('opens a list with every registered language', (t) async {
      await _menu(t);
      await _openPicker(t);
      for (final l in Languages.all) {
        expect(find.text(l.nativeName), findsWidgets, reason: l.code);
        expect(find.byKey(ValueKey('language_${l.code}')), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'active');
    });

    testWidgets('picking Türkçe retitles the whole menu at once', (t) async {
      await _menu(t);
      expect(find.text('New Run'), findsOneWidget);
      await _openPicker(t);
      await t.tap(find.byKey(const ValueKey('language_tr')));
      await t.pumpAndSettle();
      expect(find.text('Yeni Koşu'), findsOneWidget);
      expect(find.text('HIZLI OYUN'), findsOneWidget);
      expect(find.text('Nasıl Oynanır'), findsOneWidget);
      expect(find.text('Dil / Language'), findsOneWidget);
      expect(find.text('TR · Türkçe'), findsOneWidget);
      expect(find.text('New Run'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing, reason: 'modal closed');
    });

    testWidgets('and back to English again', (t) async {
      await _menu(t, saved: 'tr');
      await _openPicker(t);
      await t.tap(find.byKey(const ValueKey('language_en')));
      await t.pumpAndSettle();
      expect(find.text('New Run'), findsOneWidget);
      expect(find.text('QUICK PLAY'), findsOneWidget);
    });

    testWidgets('How to Play opens in the active language', (t) async {
      await _menu(t, saved: 'tr');
      await t.tap(find.text('Nasıl Oynanır'));
      await t.pumpAndSettle();
      expect(find.text('Amaç'), findsOneWidget);
      expect(find.text('Kombo'), findsOneWidget);
    });
  });

  group('remembering the language', () {
    testWidgets('the choice is saved to shared_preferences', (t) async {
      final (_, prefs) = await _menu(t);
      expect(prefs.getString(LanguageStore.key), isNull);
      await _openPicker(t);
      await t.tap(find.byKey(const ValueKey('language_tr')));
      await t.pumpAndSettle();
      expect(prefs.getString(LanguageStore.key), 'tr');
    });

    testWidgets('a new launch starts in the saved language', (t) async {
      await _menu(t, saved: 'tr');
      expect(find.text('Yeni Koşu'), findsOneWidget);
    });

    testWidgets('a saved choice beats the device language', (t) async {
      await _menu(t, device: 'tr', saved: 'en');
      expect(find.text('New Run'), findsOneWidget);
    });
  });

  group('following the device language', () {
    testWidgets('a Turkish phone gets Turkish with nothing saved', (t) async {
      final (_, prefs) = await _menu(t, device: 'tr');
      expect(find.text('Yeni Koşu'), findsOneWidget);
      expect(prefs.getString(LanguageStore.key), isNull, reason: 'not saved');
    });

    testWidgets('an unsupported phone language gets English', (t) async {
      await _menu(t, device: 'ja');
      expect(find.text('New Run'), findsOneWidget);
    });
  });

  testWidgets('switching language never touches the run', (t) async {
    final (c, _) = await _menu(t);
    final before = c.read(runProvider).seed;
    c.read(languageProvider.notifier).select(Languages.turkish);
    await t.pump();
    expect(c.read(runProvider).seed, before);
  });
}
