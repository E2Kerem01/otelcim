import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/auth/presentation/account_suspended_screen.dart';
import 'package:otelcim/features/profile/presentation/notification_settings_screen.dart';
import 'package:otelcim/features/profile/presentation/privacy_settings_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';
import 'package:otelcim/shared/services/profile_service.dart';

class MockProfileService extends Mock implements ProfileService {}
class MockAuthService extends Mock implements AuthService {}
class MockAdminService extends Mock implements AdminService {}
class MockNotificationService extends Mock implements NotificationService {}

UserProfile _testProfile({
  bool isBanned = false,
  String? banReason,
  bool isSuspended = false,
  DateTime? suspensionEnd,
  String? suspensionReason,
  String? quietHoursStart,
  String? quietHoursEnd,
  Map<String, bool>? notificationPreferences,
}) {
  final now = DateTime.now();
  return UserProfile(
    id: 'user_settings_1',
    email: 'settings@example.com',
    userType: 'jobseeker',
    isBanned: isBanned,
    banReason: banReason,
    isSuspended: isSuspended,
    suspensionEnd: suspensionEnd,
    suspensionReason: suspensionReason,
    quietHoursStart: quietHoursStart,
    quietHoursEnd: quietHoursEnd,
    notificationPreferences: notificationPreferences ?? UserProfile.defaultNotificationPreferences,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_testProfile());
  });

  group('Settings & Account Status Screens', () {
    late MockProfileService mockProfileService;
    late MockAuthService mockAuthService;
    late MockAdminService mockAdminService;
    late MockNotificationService mockNotificationService;
    const testUser = AppUser(uid: 'user_settings_1', email: 'settings@example.com');

    setUp(() {
      mockProfileService = MockProfileService();
      mockAuthService = MockAuthService();
      mockAdminService = MockAdminService();
      mockNotificationService = MockNotificationService();
      when(() => mockAuthService.currentUser).thenReturn(testUser);
    });

    Widget wrapWithApp(Widget child, {UserProfile? profile}) {
      return ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(mockProfileService),
          authServiceProvider.overrideWith((ref) => mockAuthService),
          adminServiceProvider.overrideWithValue(mockAdminService),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
          authStateProvider.overrideWith((ref) => Stream.value(testUser)),
          if (profile != null)
            currentUserProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', ''), Locale('en', '')],
          home: child,
        ),
      );
    }

    Future<void> pumpScreen(
      WidgetTester tester,
      Widget child, {
      UserProfile? profile,
      bool settle = true,
    }) async {
      // Wide enough for the unexpanded Row titles in PrivacySettingsScreen in
      // the Ahem test font (its glyphs are much wider than real fonts).
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrapWithApp(child, profile: profile));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // Fixed frames: AccountSuspendedScreen never settles (see BUG-t6-12).
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    group('NotificationSettingsScreen', () {
      testWidgets('renders all notification switches and toggles preference', (tester) async {
        final profile = _testProfile();
        when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});

        await pumpScreen(tester, const NotificationSettingsScreen(), profile: profile);

        expect(find.text('Bildirim Ayarları'), findsOneWidget);
        expect(find.text('Mesajlar'), findsOneWidget);
        expect(find.text('İlan Bildirimleri'), findsOneWidget);
        expect(find.text('Sezonluk Hatırlatıcılar'), findsOneWidget);
        expect(find.text('Pazarlama ve Duyurular'), findsOneWidget);

        // Toggle Marketing switch
        final marketingSwitch = find.widgetWithText(SwitchListTile, 'Pazarlama ve Duyurular');
        await tester.tap(marketingSwitch);
        await tester.pumpAndSettle();

        final captured = verify(() => mockProfileService.updateUserProfile(captureAny())).captured;
        final updated = captured.first as UserProfile;
        expect(updated.notificationPreferences['marketing'], isTrue);
      });

      testWidgets('toggling urgent notifications calls NotificationService', (tester) async {
        final profile = _testProfile();
        when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});
        when(() => mockNotificationService.setUrgentListingsPreference(any())).thenAnswer((_) async {});

        await pumpScreen(tester, const NotificationSettingsScreen(), profile: profile);

        final urgentSwitch = find.byWidgetPredicate(
          (widget) => widget is SwitchListTile && widget.title is Text && (widget.title as Text).data != null,
        );

        if (urgentSwitch.evaluate().isNotEmpty) {
          await tester.tap(urgentSwitch.at(3)); // Urgent listings is the 4th switch
          await tester.pumpAndSettle();
          verify(() => mockNotificationService.setUrgentListingsPreference(any())).called(1);
        }
      });

      testWidgets('clears quiet hours when clear quiet hours tile is tapped', (tester) async {
        final profileWithQuietHours = _testProfile(
          quietHoursStart: '22:00',
          quietHoursEnd: '08:00',
        );
        when(() => mockProfileService.updateUserProfile(any())).thenAnswer((_) async {});

        await pumpScreen(tester, const NotificationSettingsScreen(), profile: profileWithQuietHours);

        expect(find.text('Sessiz Saatleri Temizle'), findsOneWidget);
        await tester.tap(find.text('Sessiz Saatleri Temizle'));
        await tester.pumpAndSettle();

        final captured = verify(() => mockProfileService.updateUserProfile(captureAny())).captured;
        final updated = captured.first as UserProfile;
        expect(updated.quietHoursStart, isNull);
        expect(updated.quietHoursEnd, isNull);
      });
    });

    group('PrivacySettingsScreen', () {
      testWidgets('renders KVKK info and export / delete options', (tester) async {
        await pumpScreen(tester, const PrivacySettingsScreen());

        expect(find.text('Gizlilik ve Veri Ayarları'), findsOneWidget);
        expect(find.text('Kişisel Verileriniz ve KVKK'), findsOneWidget);
        expect(find.text('Verilerimi İndir / Dışa Aktar'), findsOneWidget);
        expect(find.text('Hesabımı Kalıcı Olarak Sil'), findsOneWidget);
      });

      testWidgets('shows delete account dialog and requires SIL confirmation', (tester) async {
        await pumpScreen(tester, const PrivacySettingsScreen());

        await tester.tap(find.text('Hesabımı Sil'));
        await tester.pumpAndSettle();

        expect(find.text('Hesabınızı Silin'), findsOneWidget);
        expect(find.text('Doğrulama için hesap şifrenizi girin:'), findsOneWidget);
        expect(find.text('Onaylamak için aşağıya "SİL" yazın:'), findsOneWidget);

        // Enter wrong confirmation text
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'password123');
        await tester.enterText(textFields.at(1), 'EVET');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Hesabımı Kalıcı Olarak Sil'));
        await tester.pump();

        expect(find.text('Lütfen onay kutusuna büyük harflerle "SİL" yazın.'), findsOneWidget);
        verifyNever(() => mockAuthService.deleteAccount(password: any(named: 'password')));
      });

      testWidgets(
        'allows phone-authenticated users without password to delete their account',
        (tester) async {
          const phoneUser = AppUser(uid: 'phone_user_1', email: '', phoneNumber: '+905551234567');
          when(() => mockAuthService.currentUser).thenReturn(phoneUser);

          await pumpScreen(tester, const PrivacySettingsScreen());

          await tester.tap(find.text('Hesabımı Sil'));
          await tester.pumpAndSettle();

          final textFields = find.byType(TextField);
          // Phone user has NO password, leaves password field empty and types "SİL"
          await tester.enterText(textFields.at(0), '');
          await tester.enterText(textFields.at(1), 'SİL');

          await tester.tap(find.widgetWithText(ElevatedButton, 'Hesabımı Kalıcı Olarak Sil'));
          await tester.pump();

          // Currently, this fails with "Lütfen şifrenizi girin." because it unconditionally requires password,
          // locking phone users out of deleting their account!
          expect(find.text('Lütfen şifrenizi girin.'), findsNothing);
        },
        skip: true, // BUG-t6-07: PrivacySettingsScreen requires a non-empty password to delete account, blocking phone-only users
      );
    });

    group('AccountSuspendedScreen', () {
      testWidgets('displays banned status and ban reason', (tester) async {
        final bannedProfile = _testProfile(
          isBanned: true,
          banReason: 'Spam ve sahte ilanlar nedeniyle uzaklaştırıldınız.',
        );
        when(() => mockAdminService.getUserProfile('user_settings_1'))
            .thenAnswer((_) async => bannedProfile);

        await pumpScreen(tester, const AccountSuspendedScreen(), settle: false);

        expect(find.text('Hesabınız Yasaklandı'), findsOneWidget);
        expect(find.text('Spam ve sahte ilanlar nedeniyle uzaklaştırıldınız.'), findsOneWidget);
        expect(find.text('Çıkış Yap'), findsOneWidget);
      },
        skip: true, // BUG-t6-12: FutureProvider created inside build() -> rebuild loop, stuck on spinner, ban text never shown
      );

      testWidgets('fetches the profile once instead of on every rebuild', (tester) async {
        when(() => mockAdminService.getUserProfile('user_settings_1'))
            .thenAnswer((_) async => _testProfile(isBanned: true));

        await pumpScreen(tester, const AccountSuspendedScreen(), settle: false);

        // Each resolved future rebuilds the screen, which constructs a brand-new
        // FutureProvider and fires another Firestore read.
        verify(() => mockAdminService.getUserProfile('user_settings_1')).called(1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
        skip: true, // BUG-t6-12: FutureProvider created inside build() re-fetches getUserProfile in an endless loop
      );

      testWidgets('displays suspended status with reason and end date', (tester) async {
        final futureDate = DateTime(2026, 12, 31, 23, 59);
        final suspendedProfile = _testProfile(
          isSuspended: true,
          suspensionEnd: futureDate,
          suspensionReason: 'Şüpheli aktivite incelemesi',
        );
        when(() => mockAdminService.getUserProfile('user_settings_1'))
            .thenAnswer((_) async => suspendedProfile);

        await pumpScreen(tester, const AccountSuspendedScreen(), settle: false);

        expect(find.text('Hesabınız Askıya Alındı'), findsOneWidget);
        expect(find.text('Şüpheli aktivite incelemesi'), findsOneWidget);
        expect(find.textContaining('Askı bitiş: 31.12.2026 23:59'), findsOneWidget);
      },
        skip: true, // BUG-t6-12: FutureProvider created inside build() -> rebuild loop, stuck on spinner, suspension info never shown
      );

      testWidgets('sign out button calls AuthService.signOut', (tester) async {
        final bannedProfile = _testProfile(isBanned: true);
        when(() => mockAdminService.getUserProfile('user_settings_1'))
            .thenAnswer((_) async => bannedProfile);
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        await pumpScreen(tester, const AccountSuspendedScreen(), settle: false);

        await tester.tap(find.text('Çıkış Yap'));
        await tester.pump();

        verify(() => mockAuthService.signOut()).called(1);
      });
    });
  });
}
