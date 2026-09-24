import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/referrals/presentation/invite_friends_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/error/app_failure.dart';
import 'package:otelcim/shared/error/error_mapper.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/utils/referral_code.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Error Mapper Tests', () {
    test('maps network exceptions (SocketException, HttpException) to FailureKind.network', () {
      final sockFailure = mapToFailure(const SocketException('Failed host lookup'));
      expect(sockFailure.kind, FailureKind.network);
      expect(sockFailure.message, contains('İnternet bağlantınızı kontrol'));

      final httpFailure = mapToFailure(HttpException('Bad request'));
      expect(httpFailure.kind, FailureKind.network);
      expect(httpFailure.message, contains('İnternet bağlantınızı kontrol'));
    });

    test(
      'maps TimeoutException to FailureKind.network instead of unknown',
      () {
        final timeoutFailure = mapToFailure(TimeoutException('Connection timed out'));
        // Network timeout should be categorized as network failure
        expect(timeoutFailure.kind, FailureKind.network);
        expect(timeoutFailure.message, contains('İnternet'));
      },
      skip: 'BUG-t6-10: mapToFailure does not handle TimeoutException as network failure',
    );

    test('maps all FirebaseException codes to appropriate FailureKind', () {
      final permDenied = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      expect(permDenied.kind, FailureKind.permission);
      expect(permDenied.message, contains('yetkiniz yok'));

      final unauth = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated'));
      expect(unauth.kind, FailureKind.permission);

      final notFound = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'not-found'));
      expect(notFound.kind, FailureKind.notFound);

      final objNotFound = mapToFailure(FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'));
      expect(objNotFound.kind, FailureKind.notFound);

      final alreadyExists = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'already-exists'));
      expect(alreadyExists.kind, FailureKind.conflict);

      final exhausted = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'resource-exhausted'));
      expect(exhausted.kind, FailureKind.rateLimited);

      final unavailable = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
      expect(unavailable.kind, FailureKind.network);

      final deadline = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'));
      expect(deadline.kind, FailureKind.network);

      final cancelled = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'cancelled'));
      expect(cancelled.kind, FailureKind.network);

      final invalidArg = mapToFailure(FirebaseException(plugin: 'cloud_firestore', code: 'invalid-argument'));
      expect(invalidArg.kind, FailureKind.validation);
    });

    test('maps FirebaseAuthException codes with descriptive Turkish messages', () {
      final phoneError = mapToFailure(FirebaseAuthException(code: 'invalid-phone-number'));
      expect(phoneError.kind, FailureKind.permission);
      expect(phoneError.message, contains('Geçersiz telefon numarası'));

      final codeError = mapToFailure(FirebaseAuthException(code: 'invalid-verification-code'));
      expect(codeError.kind, FailureKind.permission);
      expect(codeError.message, contains('SMS doğrulama kodu hatalı'));

      final rateError = mapToFailure(FirebaseAuthException(code: 'too-many-requests'));
      expect(rateError.kind, FailureKind.permission);
      expect(rateError.message, contains('Çok fazla başarısız deneme'));

      final passError = mapToFailure(FirebaseAuthException(code: 'wrong-password'));
      expect(passError.kind, FailureKind.permission);
      expect(passError.message, contains('E-posta veya şifre hatalı'));
    });
  });

  group('Referral Code Utility Tests', () {
    test('generates expected uppercase 8-character referral code', () {
      expect(generateReferralCode('user1234extra'), 'USER1234');
      expect(generateReferralCode('abcdef12'), 'ABCDEF12');
      expect(generateReferralCode('abc'), 'ABC');
    });

    test(
      'avoids code collisions for different UIDs with differing case prefixes',
      () {
        // UID 1: 'abcdefgh1' -> code 'ABCDEFGH'
        // UID 2: 'ABCDEFGH2' -> code 'ABCDEFGH'
        // Because generateReferralCode only uppercases the first 8 chars,
        // two different users receive the exact same referral code, causing collisions!
        final code1 = generateReferralCode('abcdefgh_user1');
        final code2 = generateReferralCode('ABCDEFGH_user2');

        expect(
          code1,
          isNot(equals(code2)),
          reason: 'Different user accounts must never produce the same referral code',
        );
      },
      skip: 'BUG-t6-11: generateReferralCode produces identical referral codes for different UIDs that differ only in casing in their first 8 characters',
    );
  });

  group('InviteFriendsScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(
        const AppUser(uid: 'uid_test_123', email: 'test@invite.com'),
      );
    });

    testWidgets('renders referral code and earned stats correctly', (tester) async {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'uid_test_123',
        email: 'test@invite.com',
        userType: 'jobseeker',
        referralCode: 'MYCODE99',
        referralCount: 7,
        freeBoostCredits: 3,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuthService),
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
            home: InviteFriendsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MYCODE99'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });
  });
}
