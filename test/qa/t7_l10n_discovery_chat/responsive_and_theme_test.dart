import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/app/design_tokens.dart';
import 'package:otelcim/app/theme.dart';
import 'package:otelcim/core/responsive/max_width_container.dart';
import 'package:otelcim/core/responsive/responsive_layout.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/widgets/desktop_top_nav_bar.dart';

class MockAuthService extends Mock implements AuthService {}
class MockStatefulNavigationShell extends Mock implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => super.toString();
}

void main() {
  group('Responsive Layout, Breakpoints & Theme Tests', () {
    testWidgets('ResponsiveLayout selects mobile layout when width < 600', (tester) async {
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_, _) => const Text('Mobile Layout'),
            tablet: (_, _) => const Text('Tablet Layout'),
            desktop: (_, _) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('ResponsiveLayout selects tablet layout when 600 <= width < 1024', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_, _) => const Text('Mobile Layout'),
            tablet: (_, _) => const Text('Tablet Layout'),
            desktop: (_, _) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('ResponsiveLayout falls back to mobile when tablet layout is null at 600px', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_, _) => const Text('Mobile Fallback'),
            desktop: (_, _) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Fallback'), findsOneWidget);
    });

    testWidgets('ResponsiveLayout selects desktop layout when width >= 1024', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_, _) => const Text('Mobile Layout'),
            tablet: (_, _) => const Text('Tablet Layout'),
            desktop: (_, _) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
    });

    testWidgets('ResponsiveContextExtension properties check breakpoints correctly', (tester) async {
      late bool isMob;
      late bool isTab;
      late bool isDesk;
      late bool isWide;

      Widget buildProbe() {
        return Builder(
          builder: (context) {
            isMob = context.isMobile;
            isTab = context.isTablet;
            isDesk = context.isDesktop;
            isWide = context.isWideDesktop;
            return const SizedBox.shrink();
          },
        );
      }

      // 1. Mobile size (500px)
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(MaterialApp(home: buildProbe()));
      expect(isMob, isTrue);
      expect(isTab, isFalse);
      expect(isDesk, isFalse);
      expect(isWide, isFalse);

      // 2. Tablet size (800px)
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(MaterialApp(home: buildProbe()));
      expect(isMob, isFalse);
      expect(isTab, isTrue);
      expect(isDesk, isFalse);
      expect(isWide, isFalse);

      // 3. Desktop size (1100px)
      tester.view.physicalSize = const Size(1100, 800);
      await tester.pumpWidget(MaterialApp(home: buildProbe()));
      expect(isMob, isFalse);
      expect(isTab, isFalse);
      expect(isDesk, isTrue);
      expect(isWide, isFalse);

      // 4. Wide desktop size (1500px)
      tester.view.physicalSize = const Size(1500, 800);
      await tester.pumpWidget(MaterialApp(home: buildProbe()));
      expect(isMob, isFalse);
      expect(isTab, isFalse);
      expect(isDesk, isTrue);
      expect(isWide, isTrue);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('MaxWidthContainer constrains child width', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaxWidthContainer(
              maxWidth: 1000.0,
              child: SizedBox(
                width: double.infinity,
                height: 100,
                key: Key('container_child'),
              ),
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject(find.byKey(const Key('container_child'))) as RenderBox;
      expect(renderBox.size.width, equals(1000.0));
    });

    testWidgets('DesktopTopNavBar renders navigation links and brand logo', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DesktopTopNavBar(navigationShell: mockShell),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Kategoriler'), findsOneWidget);
      expect(find.text('İlan Ver'), findsWidgets); // Nav item + CTA button
      expect(find.text('Mesajlar'), findsOneWidget);
      expect(find.text('Hesabım'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
    });

    testWidgets('DesktopTopNavBar post ad button invokes goBranch(2) when logged in', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = MockAuthService();
      final mockShell = MockStatefulNavigationShell();
      when(() => mockAuth.currentUser)
          .thenReturn(const AppUser(uid: 'user_1', email: 'test@hotel.com'));
      when(() => mockShell.currentIndex).thenReturn(0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuth),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DesktopTopNavBar(navigationShell: mockShell),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the ElevatedButton CTA with label 'İlan Ver'
      final ctaButton = find.byType(ElevatedButton);
      expect(ctaButton, findsOneWidget);

      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      verify(() => mockShell.goBranch(2, initialLocation: false)).called(1);
    });

    test('otelcimTheme configuration and palette verification', () {
      expect(otelcimTheme.useMaterial3, isTrue);
      expect(otelcimTheme.colorScheme.primary, equals(otelcimBlue));
      expect(otelcimTheme.scaffoldBackgroundColor, equals(AppColors.backgroundLight));
      expect(otelcimTheme.appBarTheme.backgroundColor, equals(otelcimTheme.colorScheme.surface));
      expect(otelcimTheme.appBarTheme.elevation, equals(0));
    });

    testWidgets('DesktopTopNavBar does not throw RenderFlex overflow in German locale', (tester) async {
      tester.view.physicalSize = const Size(1024, 800); // minimum desktop width
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DesktopTopNavBar(navigationShell: mockShell),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no layout exceptions occurred
      expect(tester.takeException(), isNull);
    });
  });
}
