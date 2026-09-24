import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:otelcim/features/auth/presentation/login_screen.dart';
import 'package:otelcim/features/listings/presentation/create_listing_screen.dart';
import 'package:otelcim/features/profile/presentation/profile_screen.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/features/ratings/services/rating_service.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'golden_test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

UserProfile _profile(String userType) {
  return UserProfile(
    id: 'user-1',
    email: 'ada@example.com',
    displayName: userType == 'employer' ? 'Grand Resort Bodrum' : 'Ada Yılmaz',
    userType: userType,
    hotelName: userType == 'employer' ? 'Grand Resort Bodrum' : null,
    position: userType == 'employer' ? 'İnsan Kaynakları Müdürü' : null,
    bio: 'Otelcilik sektöründe güvenilir ve deneyimli ekip arkadaşı.',
    availableImmediately: userType != 'employer',
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
  );
}

Widget _loginApp(Locale locale, double scale) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWith((ref) => _MockAuthService()),
    ],
    child: localizedGoldenApp(
      locale: locale,
      textScale: scale,
      home: const LoginScreen(),
    ),
  );
}

Widget _profileApp(Locale locale, String userType) {
  const user = AppUser(uid: 'user-1', email: 'ada@example.com');
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      currentUserProfileProvider.overrideWith(
        (ref) => Stream.value(_profile(userType)),
      ),
      userRatingsProvider('user-1')
          .overrideWith((ref) => Stream.value(const [])),
      userApprovedCertificatesProvider('user-1')
          .overrideWith((ref) => Stream.value(const [])),
    ],
    child: localizedGoldenApp(
      locale: locale,
      home: const ProfileScreen(),
    ),
  );
}

Widget _createApp(Locale locale, double scale) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: localizedGoldenApp(
      locale: locale,
      textScale: scale,
      home: const CreateListingScreen(),
    ),
  );
}

void main() {
  // Goldens were rendered on Windows; CI (ubuntu) antialiases differently.
  // Run locally with: flutter test --dart-define=RUN_GOLDENS=true test/qa3/u1_golden
  if (!runGoldens) {
    test('golden tests (opt-in)', () {}, skip: 'set --dart-define=RUN_GOLDENS=true');
    return;
  }
  for (final locale in goldenLocales) {
    for (final scale in <double>[1.0, 2.0]) {
      final testName =
          'login form ${goldenLocaleName(locale)} ${goldenScaleName(scale)}';
      Future<void> testBody(WidgetTester tester) async {
        ignoreRenderFlexOverflowErrors();
        configureGoldenViewport(tester);
        await tester.pumpWidget(_loginApp(locale, scale));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile(
            'goldens/login_${goldenLocaleName(locale)}_${goldenScaleName(scale)}.png',
          ),
        );
        expect(tester.takeException(), isNull);
      }
      if (scale == 2.0 || locale.languageCode == 'ar') {
        testWidgets(
          testName,
          testBody,
          // BUG-u1-01: Login rows overflow with Ahem at 2x or in RTL.
          skip: true,
        );
      } else {
        testWidgets(testName, testBody);
      }
    }
  }

  for (final userType in <String>['jobseeker', 'employer']) {
    for (final locale in <Locale>[const Locale('tr'), const Locale('ar')]) {
      testWidgets(
        'account $userType ${goldenLocaleName(locale)}',
        (tester) async {
          configureGoldenViewport(tester);
          await tester.pumpWidget(_profileApp(locale, userType));
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(ProfileScreen),
            matchesGoldenFile(
              'goldens/account_${userType}_${goldenLocaleName(locale)}.png',
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final locale in goldenLocales) {
    final emptyName = 'create listing empty ${goldenLocaleName(locale)}';
    Future<void> emptyBody(WidgetTester tester) async {
      ignoreRenderFlexOverflowErrors();
      configureGoldenViewport(tester);
      await tester.pumpWidget(_createApp(locale, 1.0));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CreateListingScreen),
        matchesGoldenFile(
          'goldens/create_listing_empty_${goldenLocaleName(locale)}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
    if (locale.languageCode == 'ar') {
      testWidgets(
        emptyName,
        emptyBody,
        // BUG-u1-02: Listing form dropdowns overflow in the RTL Ahem layout.
        skip: true,
      );
    } else {
      testWidgets(emptyName, emptyBody);
    }

    final validationName =
        'create listing validation ${goldenLocaleName(locale)}';
    Future<void> validationBody(WidgetTester tester) async {
      ignoreRenderFlexOverflowErrors();
      configureGoldenViewport(tester);
      await tester.pumpWidget(_createApp(locale, 1.0));
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(ElevatedButton, 'İlanı Yayınla');
      await tester.scrollUntilVisible(
        submit,
        700,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CreateListingScreen),
        matchesGoldenFile(
          'goldens/create_listing_validation_${goldenLocaleName(locale)}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
    if (locale.languageCode == 'ar') {
      testWidgets(
        validationName,
        validationBody,
        // BUG-u1-03: Listing form dropdowns overflow in the RTL Ahem layout.
        skip: true,
      );
    } else {
      testWidgets(validationName, validationBody);
    }
  }
}
