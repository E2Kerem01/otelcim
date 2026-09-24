import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/auth/presentation/register_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/profile_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockProfileService extends Mock implements ProfileService {}

UserProfile _dummyProfile() {
  final now = DateTime.now();
  return UserProfile(
    id: 'dummy',
    email: 'dummy@test.com',
    userType: 'jobseeker',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_dummyProfile());
  });

  group('RegisterScreen & Referral Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockProfileService mockProfileService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockProfileService = MockProfileService();
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    Widget buildRegisterScreen() {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          profileServiceProvider.overrideWithValue(mockProfileService),
        ],
        child: const MaterialApp(
          // Without an explicit locale the test binding resolves to en_US and
          // the Turkish field labels below would not be found.
          locale: Locale('tr'),
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
    }

    Future<void> pumpRegister(WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pump();
    }

    testWidgets('validates full name minimum length', (tester) async {
      await pumpRegister(tester);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'user@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');

      // 1-2 char full name
      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Al');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
      await tester.pump();

      expect(find.text('Geçerli bir ad soyad girin'), findsOneWidget);
    });

    testWidgets('requires hotel name when employer role is selected', (tester) async {
      await pumpRegister(tester);

      await tester.tap(find.text('Personel Arıyorum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'hotel@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Ahmet Demir');

      // Leave Hotel Name empty
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
      await tester.pump();

      expect(find.text('İşletme adını girin'), findsOneWidget);
    });

    testWidgets('completes registration and creates initial user profile', (tester) async {
      when(() => mockAuthService.register(
            email: 'newuser@test.com',
            password: 'password123',
          )).thenAnswer((_) async => const AppUser(uid: 'user_new', email: 'newuser@test.com'));

      when(() => mockProfileService.createUserProfile(any())).thenAnswer((_) async {});

      await pumpRegister(tester);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'newuser@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Zeynep Kaya');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.register(
            email: 'newuser@test.com',
            password: 'password123',
          )).called(1);

      final captured = verify(() => mockProfileService.createUserProfile(captureAny())).captured;
      expect(captured.length, 1);
      final profile = captured.first as UserProfile;
      expect(profile.id, 'user_new');
      expect(profile.email, 'newuser@test.com');
      expect(profile.displayName, 'Zeynep Kaya');
      expect(profile.userType, 'jobseeker');
      expect(profile.referralCode, isNotEmpty);
    });

    testWidgets('resolves referral code and links referrer to new user profile', (tester) async {
      when(() => mockAuthService.register(
            email: 'referee@test.com',
            password: 'password123',
          )).thenAnswer((_) async => const AppUser(uid: 'referee_uid', email: 'referee@test.com'));

      when(() => mockProfileService.findUserIdByReferralCode('REF12345'))
          .thenAnswer((_) async => 'referrer_uid');
      when(() => mockProfileService.createUserProfile(any())).thenAnswer((_) async {});

      await pumpRegister(tester);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'referee@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Canan Yurt');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Referans Kodu (opsiyonel)'),
        'REF12345',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      verify(() => mockProfileService.findUserIdByReferralCode('REF12345')).called(1);

      final captured = verify(() => mockProfileService.createUserProfile(captureAny())).captured;
      final profile = captured.first as UserProfile;
      expect(profile.referredBy, 'referrer_uid');
    });

    testWidgets(
      'normalizes lowercase referral code to uppercase for lookup',
      (tester) async {
        when(() => mockAuthService.register(
              email: 'referee2@test.com',
              password: 'password123',
            )).thenAnswer((_) async => const AppUser(uid: 'referee_2', email: 'referee2@test.com'));

        // If user enters lowercase 'ref12345', the service lookup should search for uppercase 'REF12345'
        when(() => mockProfileService.findUserIdByReferralCode('REF12345'))
            .thenAnswer((_) async => 'referrer_owner');
        when(() => mockProfileService.createUserProfile(any())).thenAnswer((_) async {});

        await pumpRegister(tester);

        await tester.tap(find.text('İş Arıyorum'));
        await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'referee2@test.com');
        await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');
        await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Kerem Kurt');
        // User inputs lowercase code
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Referans Kodu (opsiyonel)'),
          'ref12345',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Currently, it looks up 'ref12345' in Firestore without uppercase normalization,
        // which fails to find the referral record.
        verify(() => mockProfileService.findUserIdByReferralCode('REF12345')).called(1);
      },
      skip: true, // BUG-t6-04: Referral code is not normalized to uppercase before lookup, causing lowercase inputs to fail matching
    );

    testWidgets('gracefully handles profile creation failure without getting stuck in loading state', (tester) async {
      when(() => mockAuthService.register(
            email: 'fail@test.com',
            password: 'password123',
          )).thenAnswer((_) async => const AppUser(uid: 'fail_uid', email: 'fail@test.com'));

      when(() => mockProfileService.createUserProfile(any()))
          .thenThrow(Exception('Firestore write failed'));

      await pumpRegister(tester);

      await tester.tap(find.text('İş Arıyorum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'fail@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Hata Testi');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      // Should not be stuck on spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // SnackBar with error message should be displayed
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
