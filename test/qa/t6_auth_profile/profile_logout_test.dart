import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/profile/presentation/profile_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';

void main() {
  testWidgets('sign-out confirmation requires an explicit choice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => confirmSignOut(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yapmak istediğinize emin misiniz?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yapmak istediğinize emin misiniz?'), findsNothing);
  });
}
