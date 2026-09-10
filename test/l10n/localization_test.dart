import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/l10n/app_localizations.dart';

/// Renders a real MaterialApp for each shipped locale and reads strings back
/// out of the widget tree, so a broken delegate wiring (missing locale, wrong
/// fallback) fails here rather than only in the running app.
void main() {
  late AppLocalizations captured;

  Future<void> pumpForLocale(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  test('all five locales are registered', () {
    final codes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    expect(codes, {'tr', 'en', 'ru', 'de', 'ar'});
  });

  testWidgets('Turkish (template) renders its own strings', (tester) async {
    await pumpForLocale(tester, const Locale('tr'));
    expect(captured.profileTitle, 'Hesabım');
  });

  testWidgets('English renders translated strings', (tester) async {
    await pumpForLocale(tester, const Locale('en'));
    expect(captured.loginButton, 'Sign In');
    // Previously fell back to Turkish; now translated.
    expect(captured.batchCreateButton, 'Batch create listing');
  });

  testWidgets('German renders its translated subset', (tester) async {
    await pumpForLocale(tester, const Locale('de'));
    expect(captured.loginButton, 'Anmelden');
    expect(captured.navHome, 'Start');
  });

  testWidgets('Russian renders its translated subset', (tester) async {
    await pumpForLocale(tester, const Locale('ru'));
    expect(captured.loginButton, 'Войти');
    expect(captured.navHome, 'Главная');
  });

  testWidgets('Arabic renders its translated subset', (tester) async {
    await pumpForLocale(tester, const Locale('ar'));
    expect(captured.loginButton, 'تسجيل الدخول');
    expect(captured.profileTitle, 'حسابي');
  });

  testWidgets('home feed strings are translated, not Turkish, in every locale',
      (tester) async {
    await pumpForLocale(tester, const Locale('en'));
    expect(captured.homeSearchHint, 'Search job listings...');
    expect(captured.resultCount(3), '3 results');
    expect(captured.advancedFiltersTitle, 'Advanced filters');

    await pumpForLocale(tester, const Locale('de'));
    expect(captured.homeSearchHint, 'Stellenanzeigen suchen...');
    expect(captured.employmentTypeLabel, 'Beschäftigungsart');
    expect(captured.sortOrderNewest, 'Neueste');

    await pumpForLocale(tester, const Locale('ru'));
    expect(captured.noListingsTitle, 'Пока нет объявлений');
    expect(captured.tableViewTooltip, 'Табличный вид');

    await pumpForLocale(tester, const Locale('ar'));
    expect(captured.filtersTooltip, 'عوامل التصفية');
    expect(captured.gridColumnsTooltip(2), '2 أعمدة');
    // Previously fell back to Turkish; now backfilled.
    expect(captured.seasonSummer2025, 'صيف 2025');
  });

  testWidgets('untranslated keys fall back to Turkish, not to a key name',
      (tester) async {
    await pumpForLocale(tester, const Locale('de'));
    // referralCodeLabel has no German translation yet.
    expect(captured.referralCodeLabel, 'Referans Kodu (opsiyonel)');
  });
}
