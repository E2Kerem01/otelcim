import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class FakeAuthCredential extends Fake implements AuthCredential {}
class FakePhoneAuthCredential extends Fake implements PhoneAuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(FakePhoneAuthCredential());
  });

  group('AuthService Edge Cases & Flows', () {
    late MockFirebaseAuth auth;
    late MockUser user;
    late FakeFirebaseFirestore db;
    late StreamController<User?> authStateController;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      auth = MockFirebaseAuth();
      user = MockUser();
      db = FakeFirebaseFirestore();
      authStateController = StreamController<User?>.broadcast();

      when(() => auth.authStateChanges()).thenAnswer((_) => authStateController.stream);
      when(() => auth.currentUser).thenReturn(null);
      when(() => user.uid).thenReturn('user_123');
      when(() => user.email).thenReturn('user@example.com');
      when(() => user.phoneNumber).thenReturn('+905551234567');
    });

    tearDown(() {
      unawaited(authStateController.close());
    });

    test('sends password reset email through FirebaseAuth', () async {
      when(() => auth.sendPasswordResetEmail(email: 'user@example.com'))
          .thenAnswer((_) async {});

      final service = AuthService(auth, db);
      await service.sendPasswordResetEmail(email: 'user@example.com');

      verify(() => auth.sendPasswordResetEmail(email: 'user@example.com')).called(1);
      service.dispose();
    });

    group('verifyPhoneNumber', () {
      test('completes with verificationId when codeSent callback is triggered', () async {
        when(
          () => auth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          ),
        ).thenAnswer((invocation) async {
          final codeSent = invocation.namedArguments[#codeSent] as void Function(String, int?);
          codeSent('verif_id_abc', 12345);
        });

        final service = AuthService(auth, db);
        final result = await service.verifyPhoneNumber(phoneNumber: '+905551234567');

        expect(result, 'verif_id_abc');
        service.dispose();
      });

      test('completes with verificationId on codeAutoRetrievalTimeout', () async {
        when(
          () => auth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          ),
        ).thenAnswer((invocation) async {
          final timeout = invocation.namedArguments[#codeAutoRetrievalTimeout] as void Function(String);
          timeout('verif_timeout_id');
        });

        final service = AuthService(auth, db);
        final result = await service.verifyPhoneNumber(phoneNumber: '+905551234567');

        expect(result, 'verif_timeout_id');
        service.dispose();
      });

      test('throws FirebaseAuthException when verificationFailed callback is triggered', () async {
        final exception = FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Telefon numarası geçersiz.',
        );

        when(
          () => auth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          ),
        ).thenAnswer((invocation) async {
          final onFailed = invocation.namedArguments[#verificationFailed] as void Function(FirebaseAuthException);
          // Real Firebase delivers callbacks asynchronously (platform channel),
          // after verifyPhoneNumber returns and the caller listens to the future.
          Future<void>.delayed(Duration.zero, () => onFailed(exception));
        });

        final service = AuthService(auth, db);

        await expectLater(
          service.verifyPhoneNumber(phoneNumber: 'invalid'),
          throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'invalid-phone-number')),
        );
        service.dispose();
      });

      test(
        'completes future when instant verificationCompleted fires without codeSent',
        () async {
          final credential = FakePhoneAuthCredential();
          final userCred = MockUserCredential();
          when(() => userCred.user).thenReturn(user);
          when(() => auth.signInWithCredential(credential)).thenAnswer((_) async => userCred);

          when(
            () => auth.verifyPhoneNumber(
              phoneNumber: any(named: 'phoneNumber'),
              verificationCompleted: any(named: 'verificationCompleted'),
              verificationFailed: any(named: 'verificationFailed'),
              codeSent: any(named: 'codeSent'),
              codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            ),
          ).thenAnswer((invocation) async {
            final onCompleted = invocation.namedArguments[#verificationCompleted] as void Function(PhoneAuthCredential);
            onCompleted(credential);
          });

          final service = AuthService(auth, db);
          // Currently, verifyPhoneNumber completer is NEVER completed if verificationCompleted fires,
          // causing this future to hang indefinitely.
          final result = await service.verifyPhoneNumber(phoneNumber: '+905551234567')
              .timeout(const Duration(seconds: 1));

          expect(result, isNotEmpty);
          service.dispose();
        },
        skip: 'BUG-t6-02: verifyPhoneNumber hangs forever if verificationCompleted fires without codeSent',
      );
    });

    group('signInWithSmsCode', () {
      test('signs in with credential and updates currentUser', () async {
        final userCred = MockUserCredential();
        when(() => userCred.user).thenReturn(user);
        when(() => auth.signInWithCredential(any())).thenAnswer((_) async => userCred);

        final service = AuthService(auth, db);
        final appUser = await service.signInWithSmsCode(
          verificationId: 'v_123',
          smsCode: '123456',
          rememberMe: true,
        );

        expect(appUser.uid, 'user_123');
        expect(appUser.phoneNumber, '+905551234567');
        expect(service.currentUser?.uid, 'user_123');
        service.dispose();
      });

      test('records rememberMe preference in SharedPreferences on native', () async {
        final userCred = MockUserCredential();
        when(() => userCred.user).thenReturn(user);
        when(() => auth.signInWithCredential(any())).thenAnswer((_) async => userCred);

        final service = AuthService(auth, db);
        await service.signInWithSmsCode(
          verificationId: 'v_123',
          smsCode: '123456',
          rememberMe: false,
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('auth_remember_me'), isFalse);
        service.dispose();
      });

      test('throws exception on invalid smsCode', () async {
        when(() => auth.signInWithCredential(any())).thenThrow(
          FirebaseAuthException(code: 'invalid-verification-code', message: 'Hatalı SMS kodu'),
        );

        final service = AuthService(auth, db);

        await expectLater(
          service.signInWithSmsCode(verificationId: 'v_123', smsCode: '000000'),
          throwsA(isA<FirebaseAuthException>()),
        );
        service.dispose();
      });
    });

    group('deleteAccount edge cases', () {
      test('throws exception if no user is signed in', () async {
        when(() => auth.currentUser).thenReturn(null);

        final service = AuthService(auth, db);
        await expectLater(
          service.deleteAccount(password: 'any_pass'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Giriş yapmış bir kullanıcı bulunamadı'))),
        );
        service.dispose();
      });

      test(
        'phone-only user without email deletes Firestore data before user.delete throws requires-recent-login',
        () async {
          const phoneUid = 'phone_user_1';
          when(() => user.uid).thenReturn(phoneUid);
          when(() => user.email).thenReturn(null); // phone user has no email!
          when(() => auth.currentUser).thenReturn(user);

          // Seed Firestore data
          await db.collection('user_profiles').doc(phoneUid).set(<String, dynamic>{'id': phoneUid});
          await db.collection('listings').doc('l_phone').set(<String, dynamic>{'posterId': phoneUid});

          // Simulate user.delete() failing because re-authentication was never performed for phone user!
          when(() => user.delete()).thenThrow(
            FirebaseAuthException(
              code: 'requires-recent-login',
              message: 'Bu işlem için yeniden giriş yapmalısınız.',
            ),
          );

          final service = AuthService(auth, db);

          // Expect the service to verify credentials before wiping Firestore data!
          // Currently, all Firestore collections are wiped first, then user.delete() throws,
          // leaving the user account active while all user data is irretrievably lost.
          await expectLater(
            service.deleteAccount(password: ''),
            throwsA(isA<FirebaseAuthException>()),
          );

          // In proper implementation, Firestore data must NOT be deleted if auth deletion will fail
          final profileDoc = await db.collection('user_profiles').doc(phoneUid).get();
          expect(profileDoc.exists, isTrue, reason: 'Profile data should not be deleted if account deletion fails');
          service.dispose();
        },
        skip: 'BUG-t6-03: Phone-authenticated user deleteAccount deletes all Firestore data before re-authenticating and fails user.delete()',
      );

      test('cascading delete continues even if one collection deletion fails', () async {
        const uid = 'cascade_test_user';
        when(() => user.uid).thenReturn(uid);
        when(() => user.email).thenReturn('cascade@test.com');
        when(() => auth.currentUser).thenReturn(user);

        await db.collection('user_profiles').doc(uid).set(<String, dynamic>{'id': uid});
        await db.collection('reports').doc('rep_1').set(<String, dynamic>{'reporterId': uid});
        await db.collection('boosts').doc('b_1').set(<String, dynamic>{'userId': uid});

        when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => MockUserCredential());
        when(() => user.delete()).thenAnswer((_) async {});

        final service = AuthService(auth, db);
        await service.deleteAccount(password: 'pass1234');

        // All seeded documents should be deleted
        expect((await db.collection('user_profiles').doc(uid).get()).exists, isFalse);
        expect((await db.collection('reports').doc('rep_1').get()).exists, isFalse);
        expect((await db.collection('boosts').doc('b_1').get()).exists, isFalse);
        verify(() => user.delete()).called(1);
        service.dispose();
      });
    });

    group('currentUser & authStateChanges', () {
      test('currentUser returns mapped user from Firebase user', () {
        when(() => auth.currentUser).thenReturn(user);

        final service = AuthService(auth, db);
        final current = service.currentUser;

        expect(current, isNotNull);
        expect(current!.uid, 'user_123');
        expect(current.email, 'user@example.com');
        expect(current.phoneNumber, '+905551234567');
        service.dispose();
      });

      test('currentUser returns null when no user is signed in', () {
        when(() => auth.currentUser).thenReturn(null);

        final service = AuthService(auth, db);
        expect(service.currentUser, isNull);
        service.dispose();
      });
    });
  });
}
