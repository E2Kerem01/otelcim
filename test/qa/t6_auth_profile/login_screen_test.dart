import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/auth/presentation/login_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    when(() => mockAuthService.currentUser).thenReturn(null);
  });

  Widget buildLoginScreen() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWith((ref) => mockAuthService),
      ],
      child: const MaterialApp(
        // Without an explicit locale the test binding resolves to en_US and
        // every Turkish expectation below would miss.
        locale: Locale('tr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr', ''), Locale('en', '')],
        home: LoginScreen(),
      ),
    );
  }

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildLoginScreen());
    await tester.pump();
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('system back from redirected login returns to home', (tester) async {
      final router = GoRouter(
        initialLocation: '/login?from=%2Fprofile',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((ref) => mockAuthService)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('tr'), Locale('en')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('renders header, segmented switch and email tab by default', (tester) async {
      await pumpLogin(tester);

      expect(find.text('Otelcim'), findsOneWidget);
      expect(find.text('E-posta ile Giriş'), findsOneWidget);
      expect(find.text('Telefon ile Giriş'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'E-posta'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Şifre'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Giriş Yap'), findsOneWidget);
    });

    testWidgets('opens password reset dialog with the login email and sends it', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(email: 'reset@example.com'))
          .thenAnswer((_) async {});

      await pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).first, 'reset@example.com');
      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pump();

      expect(find.text('Şifre sıfırlama'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text,
        'reset@example.com',
      );

      await tester.tap(find.text('Sıfırlama bağlantısı gönder'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.sendPasswordResetEmail(email: 'reset@example.com'))
          .called(1);
      expect(find.text('Bu e-posta ile bir hesap varsa, sıfırlama bağlantısı gönderildi.'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty email form', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
      await tester.pump();

      expect(find.text('Geçerli bir e-posta girin'), findsOneWidget);
      expect(find.text('Şifre en az 8 karakter ve en az 1 rakam içermelidir'), findsOneWidget);
      verifyNever(() => mockAuthService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          ));
    });

    testWidgets('validates email format and password complexity', (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      // Malformed email
      await tester.enterText(textFields.at(0), 'invalidemail');
      // Password with 8+ chars but no numbers
      await tester.enterText(textFields.at(1), 'abcdefgh');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
      await tester.pump();

      expect(find.text('Geçerli bir e-posta girin'), findsOneWidget);
      expect(find.text('Şifre en az 8 karakter ve en az 1 rakam içermelidir'), findsOneWidget);
    });

    testWidgets('submits valid email form and calls AuthService.signIn', (tester) async {
      when(() => mockAuthService.signIn(
            email: 'test@example.com',
            password: 'password123',
            rememberMe: true,
          )).thenAnswer((_) async => const AppUser(uid: 'u1', email: 'test@example.com'));

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'test@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
      await tester.pump();

      verify(() => mockAuthService.signIn(
            email: 'test@example.com',
            password: 'password123',
            rememberMe: true,
          )).called(1);
    });

    testWidgets('switches to phone tab and validates phone input', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Telefon ile Giriş'));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Telefon Numarası'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Kod Gönder'), findsOneWidget);

      // Empty submission
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kod Gönder'));
      await tester.pump();

      expect(find.text('Geçerli bir telefon numarası girin (ör: 5551234567)'), findsOneWidget);
    });

    testWidgets('normalizes phone number and initiates verifyPhoneNumber', (tester) async {
      when(() => mockAuthService.verifyPhoneNumber(
            phoneNumber: '+905551234567',
          )).thenAnswer((_) async => 'verif_id_123');

      await pumpLogin(tester);

      await tester.tap(find.text('Telefon ile Giriş'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '05551234567');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kod Gönder'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.verifyPhoneNumber(phoneNumber: '+905551234567')).called(1);

      // Verify that SMS code field and verification button are now shown
      expect(find.widgetWithText(TextFormField, 'SMS Doğrulama Kodu'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Doğrula ve Giriş Yap'), findsOneWidget);
    });

    testWidgets('validates 6-digit sms code requirement', (tester) async {
      when(() => mockAuthService.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
          )).thenAnswer((_) async => 'verif_id_123');

      await pumpLogin(tester);

      await tester.tap(find.text('Telefon ile Giriş'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '5551234567');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kod Gönder'));
      await tester.pumpAndSettle();
      // Let the "SMS doğrulama kodu gönderildi." snackbar (4s) expire; otherwise
      // the validation snackbar is queued behind it and never rendered.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Enter incomplete code (e.g. 3 digits)
      final smsField = find.widgetWithText(TextFormField, 'SMS Doğrulama Kodu');
      await tester.enterText(smsField, '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Doğrula ve Giriş Yap'));
      await tester.pump();

      expect(find.text('Lütfen 6 haneli geçerli doğrulama kodunu girin.'), findsOneWidget);
      verifyNever(() => mockAuthService.signInWithSmsCode(
            verificationId: any(named: 'verificationId'),
            smsCode: any(named: 'smsCode'),
            rememberMe: any(named: 'rememberMe'),
          ));
    });

    testWidgets('triggers rate limit lockout after 5 consecutive failures', (tester) async {
      when(() => mockAuthService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          )).thenThrow(Exception('Hatalı şifre'));

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'user@test.com');
      await tester.enterText(textFields.at(1), 'password123');

      // Fail 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();
      }

      // Check lockout banner is visible
      expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
      expect(find.textContaining('Çok fazla başarısız deneme'), findsOneWidget);

      // Button should be disabled during lockout
      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
      expect(button.onPressed, isNull);
    });

    testWidgets('toggles rememberMe checkbox state', (tester) async {
      await pumpLogin(tester);

      final checkboxFinder = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      await tester.tap(checkboxFinder);
      await tester.pump();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
    });
  });
}
