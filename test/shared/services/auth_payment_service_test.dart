import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/payment_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockInAppPurchase extends Mock implements InAppPurchase {}
class MockPurchaseDetails extends Mock implements PurchaseDetails {}

void main() {
  group('AuthService', () {
    late MockFirebaseAuth auth;
    late MockUser user;
    late StreamController<User?> authController;
    late FakeFirebaseFirestore db;

    setUp(() {
      auth = MockFirebaseAuth();
      user = MockUser();
      db = FakeFirebaseFirestore();
      authController = StreamController<User?>.broadcast();
      when(() => auth.authStateChanges()).thenAnswer((_) => authController.stream);
      when(() => auth.currentUser).thenReturn(null);
      when(() => user.uid).thenReturn('u1');
      when(() => user.email).thenReturn('u@test.com');
    });

    tearDown(() => authController.close());

    test('signIn maps credential to AppUser', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => auth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => credential);
      final service = AuthService(auth, db);
      final result = await service.signIn(email: 'u@test.com', password: 'secret');
      expect(result.uid, 'u1');
      expect(result.email, 'u@test.com');
      service.dispose();
    });

    test('register writes user, exposes one-shot registration flag', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => auth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => credential);
      final service = AuthService(auth, db);
      await service.register(email: 'u@test.com', password: 'secret');
      expect((await db.collection('users').doc('u1').get()).exists, isTrue);
      expect(service.consumeJustRegistered(), isTrue);
      expect(service.consumeJustRegistered(), isFalse);
      service.dispose();
    });

    test('authStateChanges maps users and signOut clears state', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      final service = AuthService(auth, db);
      final expectation = expectLater(service.authStateChanges(), emitsInOrder([isNotNull, isNull]));
      authController.add(user);
      authController.add(null);
      await expectation;
      await service.signOut();
      verify(() => auth.signOut()).called(1);
      service.dispose();
    });
  });

  group('PaymentService', () {
    test('unavailable store keeps products empty and refuses purchase', () async {
      final iap = MockInAppPurchase();
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      when(() => iap.purchaseStream).thenAnswer((_) => const Stream.empty());
      final service = PaymentService(iap);
      await Future<void>.delayed(Duration.zero);
      expect(service.isAvailable, isFalse);
      expect(service.products, isEmpty);
      expect(service.getProductById('missing'), isNull);
      service.dispose();
    });

    test('verifyPurchase accepts purchased/restored and rejects pending', () async {
      final iap = MockInAppPurchase();
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      when(() => iap.purchaseStream).thenAnswer((_) => const Stream.empty());
      final purchase = MockPurchaseDetails();
      final service = PaymentService(iap);
      when(() => purchase.status).thenReturn(PurchaseStatus.purchased);
      expect(service.verifyPurchase(purchase), isTrue);
      when(() => purchase.status).thenReturn(PurchaseStatus.restored);
      expect(service.verifyPurchase(purchase), isTrue);
      when(() => purchase.status).thenReturn(PurchaseStatus.pending);
      expect(service.verifyPurchase(purchase), isFalse);
      service.dispose();
    });
  });
}
