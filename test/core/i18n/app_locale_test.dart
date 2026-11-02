import 'package:blastro/core/i18n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('which language to start in', () {
    test('a saved choice wins over the device language', () {
      expect(AppLocale.resolve(saved: 'en', device: 'tr').code, 'en');
      expect(AppLocale.resolve(saved: 'tr', device: 'en').code, 'tr');
    });

    test('with nothing saved it follows the device language', () {
      expect(AppLocale.resolve(device: 'tr').code, 'tr');
      expect(AppLocale.resolve(device: 'en').code, 'en');
    });

    test('an unsupported device language falls back to English', () {
      expect(AppLocale.resolve(device: 'ja').code, 'en');
      expect(AppLocale.resolve(device: null).code, 'en');
    });

    test('a stale saved language (removed later) is ignored', () {
      expect(AppLocale.resolve(saved: 'xx', device: 'tr').code, 'tr');
      expect(AppLocale.resolve(saved: 'xx', device: 'ja').code, 'en');
    });
  });
}
