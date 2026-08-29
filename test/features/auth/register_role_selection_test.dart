import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/auth/presentation/register_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';

void main() {
  Widget wrap() => const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('tr', ''), Locale('en', '')],
          home: RegisterScreen(),
        ),
      );

  Future<void> pumpNarrow(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pump();
  }

  group('RegisterScreen role selection', () {
    testWidgets('shows both account-type options', (tester) async {
      await pumpNarrow(tester);

      expect(find.text('Hesap türü'), findsOneWidget);
      expect(find.text('İş Arıyorum'), findsOneWidget);
      expect(find.text('Personel Arıyorum'), findsOneWidget);
    });

    testWidgets('blocks registration and shows an error when no role is picked',
        (tester) async {
      await pumpNarrow(tester);

      await tester.enterText(
          find.byType(TextFormField).at(0), 'yeni@kullanici.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'sifre1234');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Lütfen bir hesap türü seçin'), findsOneWidget);
      // Still on the form, not in a loading state.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('employer choice reveals the business-name field', (tester) async {
      await pumpNarrow(tester);

      expect(find.widgetWithText(TextFormField, 'Otel / İşletme Adı'),
          findsNothing);

      await tester.tap(find.text('Personel Arıyorum'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Otel / İşletme Adı'),
          findsOneWidget);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Otel / İşletme Adı'),
          findsNothing);
    });

    testWidgets('picking a role clears the "pick a role" error', (tester) async {
      await pumpNarrow(tester);

      await tester.enterText(
          find.byType(TextFormField).at(0), 'yeni@kullanici.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'sifre1234');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Lütfen bir hesap türü seçin'), findsOneWidget);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.pump();
      expect(find.text('Lütfen bir hesap türü seçin'), findsNothing);
    });
  });
}
