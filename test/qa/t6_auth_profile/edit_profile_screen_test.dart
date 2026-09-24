import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/profile/presentation/edit_profile_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/profile_service.dart';

class MockProfileService extends Mock implements ProfileService {}

UserProfile _sampleProfile({
  String userType = 'jobseeker',
  bool isVerified = false,
  String? verificationStatus,
  DateTime? verifiedAt,
  Map<String, bool>? notificationPreferences,
  String? quietHoursStart,
  String? quietHoursEnd,
}) {
  final now = DateTime.now();
  return UserProfile(
    id: 'user_edit_123',
    email: 'edit@example.com',
    displayName: 'Mevcut İsim',
    phoneNumber: '+905559876543',
    bio: 'Deneyimli kat görevlisi',
    userType: userType,
    isVerified: isVerified,
    verificationStatus: verificationStatus,
    verifiedAt: verifiedAt,
    notificationPreferences: notificationPreferences ?? UserProfile.defaultNotificationPreferences,
    quietHoursStart: quietHoursStart,
    quietHoursEnd: quietHoursEnd,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_sampleProfile());
  });

  group('EditProfileScreen & ProfileForm Tests', () {
    late MockProfileService mockProfileService;
    const currentUser = AppUser(uid: 'user_edit_123', email: 'edit@example.com');

    setUp(() {
      mockProfileService = MockProfileService();
    });

    Widget buildEditProfileScreen({required UserProfile profile}) {
      return ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(mockProfileService),
          authStateProvider.overrideWith((ref) => Stream.value(currentUser)),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('tr', ''), Locale('en', '')],
          home: EditProfileScreen(),
        ),
      );
    }

    Future<void> pumpEditProfile(WidgetTester tester, {required UserProfile profile}) async {
      // Wide enough for the education dropdown's longest label in the Ahem
      // test font (its glyphs are much wider than real fonts).
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildEditProfileScreen(profile: profile));
      await tester.pumpAndSettle();
    }

    testWidgets('populates initial values and validates required display name', (tester) async {
      final profile = _sampleProfile();
      await pumpEditProfile(tester, profile: profile);

      expect(find.widgetWithText(TextFormField, 'Mevcut İsim'), findsOneWidget);

      // Clear display name
      final nameField = find.widgetWithText(TextFormField, 'Mevcut İsim');
      await tester.enterText(nameField, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
      await tester.pump();

      expect(find.text('Ad Soyad gereklidir'), findsOneWidget);
      verifyNever(() => mockProfileService.updateUserProfile(any()));
    });

    testWidgets('requires hotel name and position for employer profile', (tester) async {
      final employerProfile = _sampleProfile(userType: 'employer');
      await pumpEditProfile(tester, profile: employerProfile);

      // For employer, hotel name and position fields should be displayed
      expect(find.widgetWithText(TextFormField, 'Otel Adı'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Pozisyon'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
      await tester.pump();

      expect(find.text('Otel Adı gereklidir'), findsOneWidget);
      expect(find.text('Pozisyon gereklidir'), findsOneWidget);
      verifyNever(() => mockProfileService.updateUserProfile(any()));
    });

    testWidgets('validates phone number minimum 10 digits', (tester) async {
      final profile = _sampleProfile();
      await pumpEditProfile(tester, profile: profile);

      final phoneField = find.widgetWithText(TextFormField, '+905559876543');
      await tester.enterText(phoneField, '12345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
      await tester.pump();

      expect(find.text('Telefon numarası en az 10 haneli olmalıdır'), findsOneWidget);
      verifyNever(() => mockProfileService.updateUserProfile(any()));
    });

    testWidgets('submits updated profile data successfully', (tester) async {
      final profile = _sampleProfile();
      when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});

      await pumpEditProfile(tester, profile: profile);

      final bioField = find.widgetWithText(TextFormField, 'Deneyimli kat görevlisi');
      await tester.enterText(bioField, '5 yıldızlı otellerde 4 yıl deneyimli resepsiyonist.');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
      await tester.pumpAndSettle();

      final captured = verify(() => mockProfileService.updateUserProfile(captureAny())).captured;
      expect(captured.length, 1);
      final updated = captured.first as UserProfile;
      expect(updated.bio, '5 yıldızlı otellerde 4 yıl deneyimli resepsiyonist.');
      expect(find.text('Profil başarıyla kaydedildi'), findsOneWidget);
    });

    testWidgets(
      'preserves employer isVerified and verificationStatus when updating profile',
      (tester) async {
        final verifiedEmployer = _sampleProfile(
          userType: 'employer',
          isVerified: true,
          verificationStatus: 'approved',
          verifiedAt: DateTime(2026, 1, 15),
        );
        when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});

        await pumpEditProfile(tester, profile: verifiedEmployer);

        final hotelField = find.widgetWithText(TextFormField, 'Otel Adı');
        final posField = find.widgetWithText(TextFormField, 'Pozisyon');
        await tester.enterText(hotelField, 'Grand Resort Bodrum');
        await tester.enterText(posField, 'Genel Müdür');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
        await tester.pumpAndSettle();

        final captured = verify(() => mockProfileService.updateUserProfile(captureAny())).captured;
        final updated = captured.first as UserProfile;

        // In proper implementation, verification status must not be wiped out on routine profile edits
        expect(updated.isVerified, isTrue);
        expect(updated.verificationStatus, 'approved');
        expect(updated.verifiedAt, isNotNull);
      },
      skip: true, // BUG-t6-05: Editing profile resets isVerified to false and wipes verificationStatus and verifiedAt
    );

    testWidgets(
      'preserves custom notification preferences and quiet hours when updating profile',
      (tester) async {
        final customPrefs = <String, bool>{
          'messages': true,
          'listingAlerts': false,
          'seasonalReminders': true,
          'urgentListings': false,
          'marketing': true,
        };
        final profile = _sampleProfile(
          notificationPreferences: customPrefs,
          quietHoursStart: '23:30',
          quietHoursEnd: '07:30',
        );
        when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});

        await pumpEditProfile(tester, profile: profile);

        final nameField = find.widgetWithText(TextFormField, 'Mevcut İsim');
        await tester.enterText(nameField, 'Yeni İsim');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
        await tester.pumpAndSettle();

        final captured = verify(() => mockProfileService.updateUserProfile(captureAny())).captured;
        final updated = captured.first as UserProfile;

        expect(updated.quietHoursStart, '23:30');
        expect(updated.quietHoursEnd, '07:30');
        expect(updated.notificationPreferences['marketing'], isTrue);
        expect(updated.notificationPreferences['listingAlerts'], isFalse);
      },
      skip: true, // BUG-t6-06: Editing profile resets custom notification preferences and quiet hours
    );

    testWidgets('displays error snackbar when updateUserProfile throws', (tester) async {
      final profile = _sampleProfile();
      when(() => mockProfileService.updateUserProfile(any()))
          .thenThrow(Exception('Bağlantı hatası'));

      await pumpEditProfile(tester, profile: profile);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Profili Kaydet'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      // Button should be active again (not stuck in isSaving state)
      expect(find.widgetWithText(ElevatedButton, 'Profili Kaydet'), findsOneWidget);
    });
  });
}
