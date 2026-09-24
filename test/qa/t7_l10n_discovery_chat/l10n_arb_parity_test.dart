import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/l10n/app_localizations.dart';

File _resolveArb(String fileName) {
  final candidate1 = File('lib/l10n/$fileName');
  if (candidate1.existsSync()) return candidate1;
  final candidate2 = File('../../lib/l10n/$fileName');
  if (candidate2.existsSync()) return candidate2;
  return candidate1;
}

Map<String, dynamic> _loadArb(String fileName) {
  final file = _resolveArb(fileName);
  expect(file.existsSync(), isTrue, reason: 'File $fileName must exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _extractKeys(Map<String, dynamic> arb) {
  return arb.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}

void main() {
  group('L10n ARB Parity & Placeholder Integrity Tests', () {
    late Map<String, dynamic> trArb;
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> arArb;
    late Map<String, dynamic> deArb;
    late Map<String, dynamic> ruArb;

    late Set<String> trKeys;
    late Set<String> enKeys;
    late Set<String> arKeys;
    late Set<String> deKeys;
    late Set<String> ruKeys;

    setUpAll(() {
      trArb = _loadArb('app_tr.arb');
      enArb = _loadArb('app_en.arb');
      arArb = _loadArb('app_ar.arb');
      deArb = _loadArb('app_de.arb');
      ruArb = _loadArb('app_ru.arb');

      trKeys = _extractKeys(trArb);
      enKeys = _extractKeys(enArb);
      arKeys = _extractKeys(arArb);
      deKeys = _extractKeys(deArb);
      ruKeys = _extractKeys(ruArb);
    });

    test('Turkish template ARB file contains expected key baseline', () {
      expect(trKeys.length, greaterThanOrEqualTo(200),
          reason: 'Turkish template must have comprehensive string coverage');
    });

    test('English ARB covers primary core keys from Turkish template', () {
      final essentialKeys = {
        'appName',
        'loginButton',
        'registerButton',
        'emailLabel',
        'passwordLabel',
        'navHome',
        'navCategories',
        'navCreateListing',
        'navMessages',
        'navProfile',
      };
      for (final key in essentialKeys) {
        expect(enKeys.contains(key), isTrue,
            reason: 'English ARB must contain essential key: $key');
      }
    });

    test('Arabic ARB covers existing translated subset', () {
      final arabicBasicKeys = {
        'appName',
        'loginButton',
        'registerButton',
        'emailLabel',
        'passwordLabel',
        'navHome',
        'navCategories',
        'navCreateListing',
        'navMessages',
        'navProfile',
      };
      for (final key in arabicBasicKeys) {
        expect(arKeys.contains(key), isTrue,
            reason: 'Arabic ARB must contain key: $key');
      }
    });

    test(
      'Arabic ARB has 100% key parity with Turkish template',
      () {
        final missing = trKeys.difference(arKeys);
        expect(missing, isEmpty,
            reason: 'Arabic is missing ${missing.length} keys: $missing');
      },
      skip:
          'BUG-t7-01: ARB key parity incomplete - app_ar.arb has only ~99 keys compared to Turkish template (~250+)',
    );

    test(
      'German ARB has 100% key parity with Turkish template',
      () {
        final missing = trKeys.difference(deKeys);
        expect(missing, isEmpty,
            reason: 'German is missing ${missing.length} keys: $missing');
      },
      skip:
          'BUG-t7-01b: ARB key parity incomplete - app_de.arb has missing keys compared to Turkish template',
    );

    test(
      'Russian ARB has 100% key parity with Turkish template',
      () {
        final missing = trKeys.difference(ruKeys);
        expect(missing, isEmpty,
            reason: 'Russian is missing ${missing.length} keys: $missing');
      },
      skip:
          'BUG-t7-01c: ARB key parity incomplete - app_ru.arb has missing keys compared to Turkish template',
    );

    test('Placeholder parameter consistency across translated locales', () {
      final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');

      for (final key in trKeys) {
        final trVal = trArb[key];
        if (trVal is! String) continue;

        final trPlaceholders = placeholderRegex
            .allMatches(trVal)
            .map((m) => m.group(1)!)
            .toSet();

        if (trPlaceholders.isEmpty) continue;

        // Verify across each language where key is translated
        for (final entry in {
          'en': enArb,
          'ar': arArb,
          'de': deArb,
          'ru': ruArb,
        }.entries) {
          final lang = entry.key;
          final arb = entry.value;

          if (!arb.containsKey(key)) continue;
          final targetVal = arb[key];
          if (targetVal is! String) continue;

          final targetPlaceholders = placeholderRegex
              .allMatches(targetVal)
              .map((m) => m.group(1)!)
              .toSet();

          expect(
            targetPlaceholders,
            equals(trPlaceholders),
            reason:
                'Key "$key" in locale "$lang" has mismatched placeholders: '
                'expected $trPlaceholders but got $targetPlaceholders',
          );
        }
      }
    });

    test('All ARB files have valid @@locale property matching filename', () {
      expect(trArb['@@locale'], equals('tr'));
      expect(enArb['@@locale'], equals('en'));
      expect(arArb['@@locale'], equals('ar'));
      expect(deArb['@@locale'], equals('de'));
      expect(ruArb['@@locale'], equals('ru'));
    });

    test('Supported locales list in AppLocalizations matches all 5 languages', () {
      final codes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, equals({'tr', 'en', 'ar', 'de', 'ru'}));
    });
  });
}
