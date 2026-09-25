import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otelcim/features/profile/presentation/profile_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';

void main() {
  testWidgets('admin panel tile pushes /admin', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: AdminPanelMenuTile()),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => const Scaffold(body: Text('admin-home')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yönetim Paneli'), findsOneWidget);
    await tester.tap(find.text('Yönetim Paneli'));
    await tester.pumpAndSettle();
    expect(find.text('admin-home'), findsOneWidget);
  });
}
