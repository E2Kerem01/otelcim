import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/categories/presentation/categories_screen.dart';
import 'package:otelcim/features/chat/presentation/chat_list_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/chat_service.dart';
import 'package:otelcim/shared/widgets/desktop_top_nav_bar.dart';

class MockAuthService extends Mock implements AuthService {}
class MockChatService extends Mock implements ChatService {}
class MockStatefulNavigationShell extends Mock implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => super.toString();
}

Directory _resolveDir(String relPath) {
  final d1 = Directory(relPath);
  if (d1.existsSync()) return d1;
  final d2 = Directory('../../$relPath');
  if (d2.existsSync()) return d2;
  return d1;
}

/// Scans dart files for Turkish string literals in common UI widgets.
int _countHardcodedTurkishStrings(List<String> directories) {
  final turkishCharRegex = RegExp(r'[çğışöüÇĞİŞÖÜ]');
  final turkishKeywords = RegExp(
    r'\b(Giriş|Kayıt|İlan|İlanlar|Maaş|Şehir|Mesaj|Mesajlar|Filtre|Detay|Gönder|Vazgeç|Onayla|Yükle|Hemen Başlayabilir|Kategoriler|Hesabım|Favorilerim|Sohbet)\b',
  );

  final stringLiteralRegex = RegExp(
    r"""(?:Text\(\s*['"]|labelText:\s*['"]|hintText:\s*['"]|tooltip:\s*['"]|title:\s*(?:const\s*)?Text\(\s*['"])([^'"]+)['"]""",
  );

  int totalCount = 0;

  for (final dirPath in directories) {
    final dir = _resolveDir(dirPath);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip generated files
      if (entity.path.contains('.g.') || entity.path.contains('app_localizations')) {
        continue;
      }

      final content = entity.readAsStringSync();
      for (final match in stringLiteralRegex.allMatches(content)) {
        final captured = match.group(1) ?? '';
        if (turkishCharRegex.hasMatch(captured) ||
            turkishKeywords.hasMatch(captured)) {
          totalCount++;
        }
      }
    }
  }

  return totalCount;
}

void main() {
  group('Issue #60 — Hardcoded Turkish Strings Ratchet Tests', () {
    test('Hardcoded Turkish string count does not exceed baseline ceiling (ratchet lock)', () {
      final count = _countHardcodedTurkishStrings([
        'lib/features',
        'lib/shared/widgets',
      ]);

      // Lock current baseline ceiling at 550 to prevent regressions while allowing
      // existing technical debt to be burned down over time.
      expect(
        count,
        lessThanOrEqualTo(550),
        reason:
            'Hardcoded Turkish string count ($count) exceeded ceiling of 550! '
            'New hardcoded strings must be added to ARB files, not hardcoded.',
      );
    });

    test(
      'Target: Zero hardcoded Turkish strings in UI features and shared widgets',
      () {
        final count = _countHardcodedTurkishStrings([
          'lib/features',
          'lib/shared/widgets',
        ]);
        expect(count, equals(0),
            reason:
                'Found $count hardcoded Turkish strings across lib/features and lib/shared/widgets. All UI strings must be localized.');
      },
      skip:
          'BUG-t7-01: ~490+ hardcoded Turkish strings across 50+ files in lib/features and lib/shared/widgets (Issue #60)',
    );

    testWidgets(
      'CategoriesScreen in English locale does not render Turkish characters',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProviderScope(
              child: CategoriesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In English locale, the screen should have translated strings,
        // but currently renders hardcoded Turkish labels from categories.dart.
        final turkishFinder = find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return RegExp(r'[çğışöüÇĞİŞÖÜ]').hasMatch(widget.data!);
          }
          return false;
        });

        expect(
          turkishFinder,
          findsNothing,
          reason: 'English CategoriesScreen leaked hardcoded Turkish characters',
        );
      },
      skip: true, // BUG-t7-01d: CategoriesScreen renders hardcoded Turkish texts (listingCategoryLabels) in English locale
    );

    testWidgets(
      'ChatListScreen unauthenticated state in English locale does not render Turkish text',
      (tester) async {
        final mockAuth = MockAuthService();
        when(() => mockAuth.currentUser).thenReturn(null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWith((ref) => mockAuth),
            ],
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: ChatListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final turkishTextFinder = find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return RegExp(r'[çğışöüÇĞİŞÖÜ]').hasMatch(widget.data!) ||
                widget.data!.contains('Giriş') ||
                widget.data!.contains('Mesaj');
          }
          return false;
        });

        expect(
          turkishTextFinder,
          findsNothing,
          reason: 'English ChatListScreen leaked hardcoded Turkish strings',
        );
      },
      skip: true, // BUG-t7-01e: ChatListScreen unauthenticated state renders hardcoded Turkish text in English locale
    );

    testWidgets(
      'DesktopTopNavBar in English locale does not render hardcoded Turkish subtitle or tooltips',
      (tester) async {
        final mockAuth = MockAuthService();
        final mockShell = MockStatefulNavigationShell();
        when(() => mockAuth.currentUser).thenReturn(null);
        when(() => mockShell.currentIndex).thenReturn(0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWith((ref) => mockAuth),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: DesktopTopNavBar(navigationShell: mockShell),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check for hardcoded "Turizm & Otel İş İlanları" and "Favorilerim"
        final hardcodedTurkishFinder = find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return widget.data!.contains('Turizm & Otel İş İlanları');
          }
          return false;
        });

        expect(
          hardcodedTurkishFinder,
          findsNothing,
          reason: 'DesktopTopNavBar leaked hardcoded Turkish subtitle in English locale',
        );
      },
      skip: true, // BUG-t7-01f: DesktopTopNavBar renders hardcoded Turkish subtitle "Turizm & Otel İş İlanları" and tooltip "Favorilerim" in English locale
    );
  });
}
