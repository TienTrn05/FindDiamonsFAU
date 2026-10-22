import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/core/localization/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all eight offline catalogs contain the same messages and placeholders',
    () async {
      final english =
          jsonDecode(await rootBundle.loadString('assets/l10n/en.json'))
              as Map<String, dynamic>;
      for (final code in AppTranslations.languageCodes) {
        final catalog =
            jsonDecode(await rootBundle.loadString('assets/l10n/$code.json'))
                as Map<String, dynamic>;
        expect(catalog.keys.toSet(), english.keys.toSet(), reason: code);
        for (final entry in catalog.entries) {
          expect(
            (entry.value as String).trim(),
            isNotEmpty,
            reason: '$code: ${entry.key}',
          );
          Set<String> placeholders(String text) => RegExp(
            r'\{[a-zA-Z]+\}',
          ).allMatches(text).map((match) => match.group(0)!).toSet();
          expect(
            placeholders(entry.value),
            placeholders(entry.key),
            reason: '$code: ${entry.key}',
          );
        }
      }
    },
  );

  test(
    'translated templates preserve seeds, addresses and named values',
    () async {
      final french = await AppTranslations.load(const Locale('fr'));
      expect(french.trans('Diamond coordinates'), 'Coordonnées de Diamant');
      expect(
        french.trans('Seed: -1234567890123456789'),
        'Graine : -1234567890123456789',
      );
      expect(french.trans('demo-complex.example'), 'demo-complex.example');
      expect(
        french.trans('https://example.com/servers/complex'),
        'https://example.com/servers/complex',
      );
      expect(french.trans('Steve'), 'Steve');
      final fallback = await AppTranslations.load(const Locale('xx'));
      expect(fallback.trans('Find'), 'Find');
    },
  );
}
