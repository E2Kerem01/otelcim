import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/profile/presentation/language_settings_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleController & LanguageSettingsScreen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocaleController initializes with a supported locale', () async {
      final controller = LocaleController();
      expect(
        kSupportedAppLocales.any((l) => l.languageCode == controller.state.languageCode),
        isTrue,
        reason: 'Initial state must be one of the supported locales',
      );
    });

    test('LocaleController loads persisted preference from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'de'});
      final controller = LocaleController();
      // Allow async _load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state, equals(const Locale('de')));
    });

    test('LocaleController ignores unsupported persisted locale string', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
      final controller = LocaleController();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state, isNot(equals(const Locale('fr'))));
    });

    test('setLocale updates state and persists valid locale code', () async {
      final controller = LocaleController();
      await controller.setLocale(const Locale('ar'));

      expect(controller.state, equals(const Locale('ar')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), equals('ar'));
    });

    test('setLocale ignores unsupported locale and leaves state unchanged', () async {
      final controller = LocaleController();
      final before = controller.state;

      await controller.setLocale(const Locale('es')); // Spanish is not supported

      expect(controller.state, equals(before));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), isNull);
    });

    test('setLocale normalizes locale with country code to languageCode only', () async {
      final controller = LocaleController();
      await controller.setLocale(const Locale('ar', 'EG'));

      expect(controller.state, equals(const Locale('ar')));
      expect(controller.state.countryCode, isNull);
    });

    test(
      'LocaleController._load does not overwrite an explicit setLocale call (race condition guard)',
      () async {
        // Mock SharedPreferences with 'ru'
        SharedPreferences.setMockInitialValues({'app_locale': 'ru'});

        final controller = LocaleController();
        // Immediately change to 'ar' before _load finishes
        await controller.setLocale(const Locale('ar'));

        // Wait for unawaited _load() to finish
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Expected: state must still be 'ar' (user choice), NOT overwritten by 'ru' from _load
        expect(controller.state, equals(const Locale('ar')));
      },
      skip:
          'BUG-t7-05: LocaleController._load race condition overwrites setLocale if _load completes after user selection (locale_service.dart:42-60)',
    );

    testWidgets('LanguageSettingsScreen renders all supported languages with native names', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'tr'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify native language names
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('LanguageSettingsScreen radio list selection changes active locale', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'tr'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Deutsch
      final deTile = find.text('Deutsch');
      expect(deTile, findsOneWidget);
      await tester.tap(deTile);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), equals('de'));
    });
  });
}
